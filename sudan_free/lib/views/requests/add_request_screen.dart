import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/user_model.dart';
import '../../models/request_model.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/sudan_locations.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_dropdown.dart';
import 'package:sudan_free/l10n/generated/app_localizations.dart';
import '../../widgets/common/smart_ai_input_button.dart';
import '../../services/ai_service.dart';

class AddRequestBottomSheet extends StatefulWidget {
  final UserModel user;

  const AddRequestBottomSheet({super.key, required this.user});

  @override
  State<AddRequestBottomSheet> createState() => _AddRequestBottomSheetState();
}

class _AddRequestBottomSheetState extends State<AddRequestBottomSheet> {
  final _textController = TextEditingController();
  String? _selectedCategory;
  String? _selectedState;
  String? _selectedLocality;
  bool _isLoading = false;
  String _loadingStatus = '';

  // Images
  final List<File> _selectedImages = [];
  static const int _maxImages = 3;

  // Audio
  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  DateTime? _recordStartTime;
  String? _recordedAudioPath;
  int? _audioDuration;
  bool _isEnhancing = false;

  @override
  void initState() {
    super.initState();
    _selectedState = widget.user.state;
    _selectedLocality = widget.user.locality;
  }

  @override
  void dispose() {
    _textController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  String _locale(BuildContext context) =>
      context.read<LocaleProvider>().locale.languageCode;

  Future<void> _pickImages() async {
    final remaining = _maxImages - _selectedImages.length;
    if (remaining <= 0) return;

    final picker = ImagePicker();

    // Show source selection
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        final locale = _locale(context);
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: AppColors.primary),
                title: Text(AppLocalizations.of(context)!.gallery),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined,
                    color: AppColors.primary),
                title: Text(AppLocalizations.of(context)!.camera),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    if (source == ImageSource.camera) {
      final image = await picker.pickImage(
          source: ImageSource.camera, imageQuality: 70, maxWidth: 1200);
      if (image != null && mounted) {
        setState(() => _selectedImages.add(File(image.path)));
      }
    } else {
      final images =
          await picker.pickMultiImage(imageQuality: 70, maxWidth: 1200);
      if (images.isNotEmpty && mounted) {
        setState(() {
          final toAdd =
              images.take(remaining).map((img) => File(img.path)).toList();
          _selectedImages.addAll(toAdd);
        });
      }
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        final path =
            '${tempDir.path}/request_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            noiseSuppress: true,
            echoCancel: true,
            autoGain: true,
          ),
          path: path,
        );

        setState(() {
          _isRecording = true;
          _recordStartTime = DateTime.now();
        });
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      if (path != null && _recordStartTime != null) {
        final duration = DateTime.now().difference(_recordStartTime!).inSeconds;
        setState(() {
          _isRecording = false;
          if (duration >= 1) {
            _recordedAudioPath = path;
            _audioDuration = duration;
          }
        });
      } else {
        setState(() => _isRecording = false);
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      setState(() => _isRecording = false);
    }
  }

  void _deleteRecording() {
    setState(() {
      _recordedAudioPath = null;
      _audioDuration = null;
    });
  }

  Future<void> _enhanceWithAi() async {
    if (_textController.text.trim().isEmpty) return;
    setState(() => _isEnhancing = true);
    try {
      final aiService = AiService();
      final enhanced = await aiService.enhanceText(_textController.text);
      if (enhanced.isNotEmpty && mounted) {
        _textController.text = enhanced;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل تحسين النص: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isEnhancing = false);
    }
  }

  Future<void> _submitRequest() async {
    final locale = _locale(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (_textController.text.trim().isEmpty) {
      messenger.showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.pleaseWriteRequestDetails),
            backgroundColor: AppColors.warning),
      );
      return;
    }

    if (_selectedCategory == null) {
      messenger.showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.pleaseSelectTheWorkType),
            backgroundColor: AppColors.warning),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingStatus = AppLocalizations.of(context)!.preparing;
    });

    try {
      // 1. Upload images if any
      List<String> uploadedUrls = [];
      if (_selectedImages.isNotEmpty) {
        setState(() => _loadingStatus = locale == 'ar'
            ? 'جاري رفع الصور (${_selectedImages.length})...'
            : 'Uploading images (${_selectedImages.length})...');

        for (int i = 0; i < _selectedImages.length; i++) {
          setState(() => _loadingStatus = locale == 'ar'
              ? 'جاري رفع الصورة ${i + 1} من ${_selectedImages.length}...'
              : 'Uploading image ${i + 1} of ${_selectedImages.length}...');

          final url = await StorageService().uploadImage(
            _selectedImages[i],
            folder:
                'requests/${widget.user.id}/${DateTime.now().millisecondsSinceEpoch}',
          );
          if (url != null) uploadedUrls.add(url);
        }
      }

      // 1.5 Upload audio if any
      String? uploadedAudioUrl;
      if (_recordedAudioPath != null) {
        setState(() => _loadingStatus = AppLocalizations.of(context)!.uploadingAudio);
        uploadedAudioUrl = await StorageService().uploadImage(
          File(_recordedAudioPath!),
          folder: 'requests/${widget.user.id}/audio',
        );
      }

      // 2. Create request
      setState(() => _loadingStatus =
          AppLocalizations.of(context)!.publishingRequest);

      final request = RequestModel(
        id: '',
        clientId: widget.user.id,
        clientName: widget.user.name,
        clientImageUrl: widget.user.profileImageUrl,
        text: _textController.text.trim(),
        category: _selectedCategory,
        imageUrls: uploadedUrls,
        audioUrl: uploadedAudioUrl,
        audioDuration: _audioDuration,
        state: _selectedState,
        locality: _selectedLocality,
        createdAt: DateTime.now(),
      );

      await FirestoreService().createRequest(request);

      if (mounted) {
        navigator.pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.yourRequestHasBeenPublishedSuccessfully),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingStatus = '';
        });
      }
    }
  }

  // Work type categories with icons
  List<Map<String, dynamic>> _getCategories(String locale) {
    return [
      {
        'key': 'Cars',
        'label': AppLocalizations.of(context)!.cars,
        'icon': Icons.directions_car_outlined,
        'color': Colors.red,
      },
      {
        'key': 'Real Estate',
        'label': AppLocalizations.of(context)!.realEstate,
        'icon': Icons.home_work_outlined,
        'color': Colors.blue,
      },
      {
        'key': 'Electronics',
        'label': AppLocalizations.of(context)!.electronics,
        'icon': Icons.devices_outlined,
        'color': Colors.indigo,
      },
      {
        'key': 'Clothes',
        'label': AppLocalizations.of(context)!.clothes,
        'icon': Icons.checkroom_outlined,
        'color': Colors.pink,
      },
      {
        'key': 'Services',
        'label': AppLocalizations.of(context)!.services,
        'icon': Icons.home_repair_service_outlined,
        'color': Colors.orange,
      },
      {
        'key': 'Food',
        'label': AppLocalizations.of(context)!.food,
        'icon': Icons.restaurant_outlined,
        'color': Colors.green,
      },
      {
        'key': 'Construction',
        'label': AppLocalizations.of(context)!.construction,
        'icon': Icons.construction_outlined,
        'color': Colors.brown,
      },
      {
        'key': 'Beauty',
        'label': AppLocalizations.of(context)!.beauty,
        'icon': Icons.face_retouching_natural,
        'color': Colors.purple,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale.languageCode;
    final categories = _getCategories(locale);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.addNewRequest,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: Colors.blue, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)!.describeYourRequestClearlyAndAttach,
                            style: TextStyle(
                                color: Colors.blue.shade700,
                                height: 1.5,
                                fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Expiration Notice Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_outlined,
                            color: Colors.orange, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)!.noticeAllRequestsAreTemporaryOffers,
                            style: TextStyle(
                                color: Colors.orange.shade800,
                                height: 1.5,
                                fontSize: 13,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ═══ 1. Work Type Selection (Chips with icons) ═══
                  Text(
                    AppLocalizations.of(context)!.workType,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 10,
                    children: categories.map((cat) {
                      final isSelected = _selectedCategory == cat['key'];
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedCategory = cat['key']),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (cat['color'] as Color)
                                    .withValues(alpha: 0.15)
                                : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? (cat['color'] as Color)
                                  : Colors.grey.withValues(alpha: 0.3),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                cat['icon'] as IconData,
                                size: 18,
                                color: isSelected
                                    ? cat['color'] as Color
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                cat['label'] as String,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color:
                                      isSelected ? cat['color'] as Color : null,
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 4),
                                Icon(Icons.check_circle,
                                    size: 16, color: cat['color'] as Color),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // ═══ 2. Request Details Text ═══
                  CustomTextField(
                    controller: _textController,
                    label:
                        AppLocalizations.of(context)!.requestDetails,
                    hint: AppLocalizations.of(context)!.exampleINeedAPlumberTo,
                    maxLines: 5,
                    prefixIcon: Icons.description_outlined,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SmartAiInputButton(
                      controller: _textController,
                      onEnhance: _enhanceWithAi,
                      isEnhancing: _isEnhancing,
                      isArabic: locale == 'ar',
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ═══ 3. Image Attachments ═══
                  Text(
                    AppLocalizations.of(context)!.attachedImagesOptional,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    locale == 'ar'
                        ? 'أضف صوراً لتوضيح طلبك بشكل أفضل (حد أقصى $_maxImages صور)'
                        : 'Add images to better explain your request (max $_maxImages)',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    height: 110,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        // Selected images
                        ..._selectedImages.asMap().entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsetsDirectional.only(end: 10),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    entry.value,
                                    width: 110,
                                    height: 110,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => setState(() =>
                                        _selectedImages.removeAt(entry.key)),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.black.withValues(alpha: 0.6),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close,
                                          color: Colors.white, size: 16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                        // Add button (if under limit)
                        if (_selectedImages.length < _maxImages)
                          GestureDetector(
                            onTap: _pickImages,
                            child: Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primary.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.3),
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_outlined,
                                      size: 32,
                                      color: AppColors.primary
                                          .withValues(alpha: 0.7)),
                                  const SizedBox(height: 4),
                                  Text(
                                    AppLocalizations.of(context)!.addPhoto,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.primary
                                            .withValues(alpha: 0.8),
                                        fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    '${_selectedImages.length}/$_maxImages',
                                    style: TextStyle(
                                        fontSize: 10, color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ═══ 4. Voice Recording ═══
                  Text(
                    AppLocalizations.of(context)!.voiceRecordOptional,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)!.youCanRecordAVoiceExplanation,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),

                  if (_recordedAudioPath != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.mic, color: AppColors.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              locale == 'ar'
                                  ? 'تم تسجيل الصوت بنجاح ($_audioDuration ثانية)'
                                  : 'Audio recorded successfully (${_audioDuration}s)',
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            onPressed: _deleteRecording,
                          ),
                        ],
                      ),
                    )
                  else if (_isRecording)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: _stopRecording,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                  color: Colors.red, shape: BoxShape.circle),
                              child: const Icon(Icons.stop,
                                  color: Colors.white, size: 24),
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Icon(Icons.fiber_manual_record,
                              color: Colors.red, size: 12),
                          const SizedBox(width: 8),
                          Expanded(
                            child: StreamBuilder<Duration>(
                              stream: Stream.periodic(
                                  const Duration(seconds: 1),
                                  (tick) => Duration(seconds: tick + 1)),
                              builder: (context, snapshot) {
                                final seconds = snapshot.data?.inSeconds ?? 0;
                                return Text(
                                  '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    InkWell(
                      onTap: _startRecording,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.mic_none,
                                color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              AppLocalizations.of(context)!.tapToStartRecording,
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // ═══ 5. Location Selection ═══
                  Text(
                    AppLocalizations.of(context)!.workLocationOptional,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)!.specifyLocationIfTheWorkRequires,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),
                  CustomDropdown(
                    label: AppLocalizations.of(context)!.state,
                    value: _selectedState,
                    items: SudanLocations.states,
                    onChanged: (val) {
                      setState(() {
                        _selectedState = val;
                        _selectedLocality = null;
                      });
                    },
                    hint: AppLocalizations.of(context)!.selectState,
                    prefixIcon: Icons.map_outlined,
                    itemLabelBuilder: (item) =>
                        SudanLocations.getStateName(item, locale),
                  ),
                  if (_selectedState != null) ...[
                    const SizedBox(height: 16),
                    CustomDropdown(
                      label: AppLocalizations.of(context)!.localityCity,
                      value: _selectedLocality,
                      items: SudanLocations
                              .statesWithLocalities[_selectedState!] ??
                          [],
                      onChanged: (val) =>
                          setState(() => _selectedLocality = val),
                      hint: AppLocalizations.of(context)!.selectLocality,
                      prefixIcon: Icons.location_city_outlined,
                      itemLabelBuilder: (item) =>
                          SudanLocations.getLocalityName(item, locale),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // ═══ Submit Button ═══
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2)),
                                const SizedBox(width: 12),
                                Text(_loadingStatus,
                                    style: const TextStyle(fontSize: 14)),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.send_rounded, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  AppLocalizations.of(context)!.postRequest,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
