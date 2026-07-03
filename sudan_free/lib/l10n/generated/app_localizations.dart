import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'SudanFree'**
  String get appName;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @signup.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signup;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccount;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get haveAccount;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @bio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// No description provided for @skills.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get skills;

  /// No description provided for @hourlyRate.
  ///
  /// In en, this message translates to:
  /// **'Hourly Rate'**
  String get hourlyRate;

  /// No description provided for @portfolio.
  ///
  /// In en, this message translates to:
  /// **'Portfolio'**
  String get portfolio;

  /// No description provided for @freelancer.
  ///
  /// In en, this message translates to:
  /// **'Freelancer'**
  String get freelancer;

  /// No description provided for @client.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get client;

  /// No description provided for @chooseRole.
  ///
  /// In en, this message translates to:
  /// **'Choose your role'**
  String get chooseRole;

  /// No description provided for @jobs.
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get jobs;

  /// No description provided for @postJob.
  ///
  /// In en, this message translates to:
  /// **'Post a Job'**
  String get postJob;

  /// No description provided for @browseJobs.
  ///
  /// In en, this message translates to:
  /// **'Browse Jobs'**
  String get browseJobs;

  /// No description provided for @myJobs.
  ///
  /// In en, this message translates to:
  /// **'My Jobs'**
  String get myJobs;

  /// No description provided for @jobTitle.
  ///
  /// In en, this message translates to:
  /// **'Job Title'**
  String get jobTitle;

  /// No description provided for @jobDescription.
  ///
  /// In en, this message translates to:
  /// **'Job Description'**
  String get jobDescription;

  /// No description provided for @budget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budget;

  /// No description provided for @deadline.
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get deadline;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @proposals.
  ///
  /// In en, this message translates to:
  /// **'Proposals'**
  String get proposals;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviews;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @submitProposal.
  ///
  /// In en, this message translates to:
  /// **'Submit Proposal'**
  String get submitProposal;

  /// No description provided for @proposedPrice.
  ///
  /// In en, this message translates to:
  /// **'Proposed Price'**
  String get proposedPrice;

  /// No description provided for @deliveryTime.
  ///
  /// In en, this message translates to:
  /// **'Delivery Time'**
  String get deliveryTime;

  /// No description provided for @coverLetter.
  ///
  /// In en, this message translates to:
  /// **'Cover Letter'**
  String get coverLetter;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @typeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeMessage;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @uploadReceipt.
  ///
  /// In en, this message translates to:
  /// **'Upload Receipt'**
  String get uploadReceipt;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// No description provided for @transactionRef.
  ///
  /// In en, this message translates to:
  /// **'Transaction Ref'**
  String get transactionRef;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error occurred'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data found'**
  String get noData;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @community.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get community;

  /// No description provided for @freelancers.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get freelancers;

  /// No description provided for @shops.
  ///
  /// In en, this message translates to:
  /// **'Shops'**
  String get shops;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get search;

  /// No description provided for @noPosts.
  ///
  /// In en, this message translates to:
  /// **'No posts yet'**
  String get noPosts;

  /// No description provided for @beFirstToShare.
  ///
  /// In en, this message translates to:
  /// **'Be the first to share!'**
  String get beFirstToShare;

  /// No description provided for @followToSeePosts.
  ///
  /// In en, this message translates to:
  /// **'Follow workers and shops to see their posts'**
  String get followToSeePosts;

  /// No description provided for @createPost.
  ///
  /// In en, this message translates to:
  /// **'Create Post'**
  String get createPost;

  /// No description provided for @newUser.
  ///
  /// In en, this message translates to:
  /// **'🆕 New User'**
  String get newUser;

  /// No description provided for @newUserWarning.
  ///
  /// In en, this message translates to:
  /// **'⚠️ This is a new freelancer without ratings\n\n• Verify their identity and reliability\n• Do not transfer any money in advance\n• Be careful sharing sensitive info'**
  String get newUserWarning;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Warning'**
  String get warning;

  /// No description provided for @lowRatingWarning.
  ///
  /// In en, this message translates to:
  /// **'⛔ This user has a low rating ({rating} ⭐)\n\n• Exercise extreme caution\n• Do not send money in advance\n• Verify all details'**
  String lowRatingWarning(Object rating);

  /// No description provided for @reminder.
  ///
  /// In en, this message translates to:
  /// **'💡 Reminder'**
  String get reminder;

  /// No description provided for @normalUserReminder.
  ///
  /// In en, this message translates to:
  /// **'• Agree on price before starting\n• Keep proof of agreement'**
  String get normalUserReminder;

  /// No description provided for @openWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get openWhatsApp;

  /// No description provided for @noWorksYet.
  ///
  /// In en, this message translates to:
  /// **'No works yet'**
  String get noWorksYet;

  /// No description provided for @addWork.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add new work'**
  String get addWork;

  /// No description provided for @loadingReviews.
  ///
  /// In en, this message translates to:
  /// **'Loading reviews...'**
  String get loadingReviews;

  /// No description provided for @reviewsError.
  ///
  /// In en, this message translates to:
  /// **'Error loading reviews'**
  String get reviewsError;

  /// No description provided for @noReviews.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get noReviews;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @platformSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Freelance platform in Sudan'**
  String get platformSubtitle;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @agreeToTerms.
  ///
  /// In en, this message translates to:
  /// **'By signing up, you agree to our Terms and Privacy Policy'**
  String get agreeToTerms;

  /// No description provided for @userNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get userNotFound;

  /// No description provided for @clientAccount.
  ///
  /// In en, this message translates to:
  /// **'Client Account'**
  String get clientAccount;

  /// No description provided for @editProfileUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile / Upgrade Account'**
  String get editProfileUpgrade;

  /// No description provided for @editStore.
  ///
  /// In en, this message translates to:
  /// **'Edit Store'**
  String get editStore;

  /// No description provided for @reportStore.
  ///
  /// In en, this message translates to:
  /// **'Report Store'**
  String get reportStore;

  /// No description provided for @addProduct.
  ///
  /// In en, this message translates to:
  /// **'Add new product'**
  String get addProduct;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @emptyStoreOwner.
  ///
  /// In en, this message translates to:
  /// **'Store is empty, start adding products'**
  String get emptyStoreOwner;

  /// No description provided for @emptyStoreVisitor.
  ///
  /// In en, this message translates to:
  /// **'No products available currently'**
  String get emptyStoreVisitor;

  /// No description provided for @storeInfo.
  ///
  /// In en, this message translates to:
  /// **'Store Info'**
  String get storeInfo;

  /// No description provided for @storeCategory.
  ///
  /// In en, this message translates to:
  /// **'Store Category'**
  String get storeCategory;

  /// No description provided for @aboutStore.
  ///
  /// In en, this message translates to:
  /// **'About Store'**
  String get aboutStore;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @workingHours.
  ///
  /// In en, this message translates to:
  /// **'Working Hours'**
  String get workingHours;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// No description provided for @undefined.
  ///
  /// In en, this message translates to:
  /// **'Undefined'**
  String get undefined;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @coverPhoto.
  ///
  /// In en, this message translates to:
  /// **'Cover Photo'**
  String get coverPhoto;

  /// No description provided for @storePhoto.
  ///
  /// In en, this message translates to:
  /// **'Store Photo'**
  String get storePhoto;

  /// No description provided for @viewImage.
  ///
  /// In en, this message translates to:
  /// **'View Image'**
  String get viewImage;

  /// No description provided for @changeImage.
  ///
  /// In en, this message translates to:
  /// **'Change Image'**
  String get changeImage;

  /// No description provided for @uploadingImage.
  ///
  /// In en, this message translates to:
  /// **'Uploading image...'**
  String get uploadingImage;

  /// No description provided for @imageUpdated.
  ///
  /// In en, this message translates to:
  /// **'Image updated successfully'**
  String get imageUpdated;

  /// No description provided for @imageUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Image upload failed'**
  String get imageUploadFailed;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to SudanFree!'**
  String get welcome;

  /// No description provided for @signupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account to start your journey'**
  String get signupSubtitle;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @reEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Re-enter password'**
  String get reEnterPassword;

  /// No description provided for @passwordsNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsNotMatch;

  /// No description provided for @readTerms.
  ///
  /// In en, this message translates to:
  /// **'Read Terms'**
  String get readTerms;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @termsConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms and Privacy'**
  String get termsConfirmTitle;

  /// No description provided for @termsConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'By clicking \'Accept\', you confirm your agreement to our Terms and Privacy Policy.'**
  String get termsConfirmContent;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get enterPassword;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password too short'**
  String get passwordTooShort;

  /// No description provided for @profilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Profile Picture'**
  String get profilePhoto;

  /// No description provided for @noWorkDisplayed.
  ///
  /// In en, this message translates to:
  /// **'No work displayed'**
  String get noWorkDisplayed;

  /// No description provided for @addReview.
  ///
  /// In en, this message translates to:
  /// **'Add your review'**
  String get addReview;

  /// No description provided for @reviewAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Review added successfully'**
  String get reviewAddedSuccessfully;

  /// No description provided for @loginToReview.
  ///
  /// In en, this message translates to:
  /// **'You must log in to add a review'**
  String get loginToReview;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details...'**
  String get viewDetails;

  /// No description provided for @completedJobs.
  ///
  /// In en, this message translates to:
  /// **'Completed Jobs'**
  String get completedJobs;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @safetyTipsTitle.
  ///
  /// In en, this message translates to:
  /// **'Safety Tips'**
  String get safetyTipsTitle;

  /// No description provided for @protectYourself.
  ///
  /// In en, this message translates to:
  /// **'Protect Yourself from Fraud'**
  String get protectYourself;

  /// No description provided for @forFreelancers.
  ///
  /// In en, this message translates to:
  /// **'For Freelancers & Workers'**
  String get forFreelancers;

  /// No description provided for @forClients.
  ///
  /// In en, this message translates to:
  /// **'For Clients'**
  String get forClients;

  /// No description provided for @safetyTipAskDeposit.
  ///
  /// In en, this message translates to:
  /// **'Request Upfront Deposit'**
  String get safetyTipAskDeposit;

  /// No description provided for @safetyTipAskDepositDesc.
  ///
  /// In en, this message translates to:
  /// **'For remote work, ask for a 30-50% deposit before starting.'**
  String get safetyTipAskDepositDesc;

  /// No description provided for @safetyTipConfirmCall.
  ///
  /// In en, this message translates to:
  /// **'Verify via Phone Call'**
  String get safetyTipConfirmCall;

  /// No description provided for @safetyTipConfirmCallDesc.
  ///
  /// In en, this message translates to:
  /// **'After agreeing on WhatsApp, call the client directly to verify identity and seriousness.'**
  String get safetyTipConfirmCallDesc;

  /// No description provided for @safetyTipVerifyAddress.
  ///
  /// In en, this message translates to:
  /// **'Verify Address'**
  String get safetyTipVerifyAddress;

  /// No description provided for @safetyTipVerifyAddressDesc.
  ///
  /// In en, this message translates to:
  /// **'Request the full address and nearby landmarks before visiting.'**
  String get safetyTipVerifyAddressDesc;

  /// No description provided for @safetyTipKeepProof.
  ///
  /// In en, this message translates to:
  /// **'Keep Proof of Agreement'**
  String get safetyTipKeepProof;

  /// No description provided for @safetyTipKeepProofDesc.
  ///
  /// In en, this message translates to:
  /// **'Keep screenshots of WhatsApp conversations as proof of agreement and price.'**
  String get safetyTipKeepProofDesc;

  /// No description provided for @safetyTipCheckReviews.
  ///
  /// In en, this message translates to:
  /// **'Check Reviews'**
  String get safetyTipCheckReviews;

  /// No description provided for @safetyTipCheckReviewsDesc.
  ///
  /// In en, this message translates to:
  /// **'Read reviews from previous clients before hiring a freelancer.'**
  String get safetyTipCheckReviewsDesc;

  /// No description provided for @safetyTipSeePortfolio.
  ///
  /// In en, this message translates to:
  /// **'Check Portfolio'**
  String get safetyTipSeePortfolio;

  /// No description provided for @safetyTipSeePortfolioDesc.
  ///
  /// In en, this message translates to:
  /// **'View previous work photos to verify quality.'**
  String get safetyTipSeePortfolioDesc;

  /// No description provided for @safetyTipAgreePrice.
  ///
  /// In en, this message translates to:
  /// **'Agree on Price Upfront'**
  String get safetyTipAgreePrice;

  /// No description provided for @safetyTipAgreePriceDesc.
  ///
  /// In en, this message translates to:
  /// **'Agree on the full price before work starts and pay only half as a deposit.'**
  String get safetyTipAgreePriceDesc;

  /// No description provided for @safetyWarningDesc.
  ///
  /// In en, this message translates to:
  /// **'Do not send money to people you haven\'t worked with before without guarantees.'**
  String get safetyWarningDesc;

  /// No description provided for @adminDashboard.
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard'**
  String get adminDashboard;

  /// No description provided for @verificationRequests.
  ///
  /// In en, this message translates to:
  /// **'Verification Requests'**
  String get verificationRequests;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @milestones.
  ///
  /// In en, this message translates to:
  /// **'Milestones'**
  String get milestones;

  /// No description provided for @activeJobs.
  ///
  /// In en, this message translates to:
  /// **'Active Projects'**
  String get activeJobs;

  /// No description provided for @startProject.
  ///
  /// In en, this message translates to:
  /// **'Start Project'**
  String get startProject;

  /// No description provided for @acceptOffer.
  ///
  /// In en, this message translates to:
  /// **'Accept Offer'**
  String get acceptOffer;

  /// No description provided for @completeJob.
  ///
  /// In en, this message translates to:
  /// **'Complete Project'**
  String get completeJob;

  /// No description provided for @idVerification.
  ///
  /// In en, this message translates to:
  /// **'ID Verification'**
  String get idVerification;

  /// No description provided for @advancedVerification.
  ///
  /// In en, this message translates to:
  /// **'Advanced Verification'**
  String get advancedVerification;

  /// No description provided for @uploadIdCard.
  ///
  /// In en, this message translates to:
  /// **'Upload ID Card'**
  String get uploadIdCard;

  /// No description provided for @pendingReview.
  ///
  /// In en, this message translates to:
  /// **'Pending Review'**
  String get pendingReview;

  /// No description provided for @professionalPortfolio.
  ///
  /// In en, this message translates to:
  /// **'Professional Portfolio'**
  String get professionalPortfolio;

  /// No description provided for @addProject.
  ///
  /// In en, this message translates to:
  /// **'Add Project'**
  String get addProject;

  /// No description provided for @searchSmartHint.
  ///
  /// In en, this message translates to:
  /// **'Search for skills, freelancers, locations...'**
  String get searchSmartHint;

  /// No description provided for @noResultsFor.
  ///
  /// In en, this message translates to:
  /// **'No results for \"{query}\"'**
  String noResultsFor(Object query);

  /// No description provided for @popularSearches.
  ///
  /// In en, this message translates to:
  /// **'Popular Searches'**
  String get popularSearches;

  /// No description provided for @legend.
  ///
  /// In en, this message translates to:
  /// **'Legend'**
  String get legend;

  /// No description provided for @master.
  ///
  /// In en, this message translates to:
  /// **'Master'**
  String get master;

  /// No description provided for @distinguished.
  ///
  /// In en, this message translates to:
  /// **'Distinguished'**
  String get distinguished;

  /// No description provided for @expert.
  ///
  /// In en, this message translates to:
  /// **'Expert'**
  String get expert;

  /// No description provided for @professional.
  ///
  /// In en, this message translates to:
  /// **'Professional'**
  String get professional;

  /// No description provided for @youreAtTheTopKeepExcelling.
  ///
  /// In en, this message translates to:
  /// **'🏆 You\\\'re at the top! Keep excelling'**
  String get youreAtTheTopKeepExcelling;

  /// No description provided for @en.
  ///
  /// In en, this message translates to:
  /// **'en'**
  String get en;

  /// No description provided for @openNow.
  ///
  /// In en, this message translates to:
  /// **'Open Now'**
  String get openNow;

  /// No description provided for @closedNow.
  ///
  /// In en, this message translates to:
  /// **'Closed Now'**
  String get closedNow;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @unavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get unavailable;

  /// No description provided for @jobs1.
  ///
  /// In en, this message translates to:
  /// **'jobs'**
  String get jobs1;

  /// No description provided for @viewProfile.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get viewProfile;

  /// No description provided for @searchShopsOrFreelancers.
  ///
  /// In en, this message translates to:
  /// **'Search shops or freelancers...'**
  String get searchShopsOrFreelancers;

  /// No description provided for @shop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get shop;

  /// No description provided for @filterMap.
  ///
  /// In en, this message translates to:
  /// **'Filter Map'**
  String get filterMap;

  /// No description provided for @strShow.
  ///
  /// In en, this message translates to:
  /// **'Show:'**
  String get strShow;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @freelancers1.
  ///
  /// In en, this message translates to:
  /// **'Freelancers'**
  String get freelancers1;

  /// No description provided for @shopCategory.
  ///
  /// In en, this message translates to:
  /// **'Shop Category:'**
  String get shopCategory;

  /// No description provided for @profession.
  ///
  /// In en, this message translates to:
  /// **'Profession:'**
  String get profession;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @sudanFree.
  ///
  /// In en, this message translates to:
  /// **'Sudan Free'**
  String get sudanFree;

  /// No description provided for @thePremierSudaneseFreelancePlatform.
  ///
  /// In en, this message translates to:
  /// **'🇸🇩 The Premier Sudanese Freelance Platform'**
  String get thePremierSudaneseFreelancePlatform;

  /// No description provided for @aboutTheApp.
  ///
  /// In en, this message translates to:
  /// **'About the App'**
  String get aboutTheApp;

  /// No description provided for @sudanFreeIsTheFirstIntegrated.
  ///
  /// In en, this message translates to:
  /// **'Sudan Free is the first integrated Sudanese platform connecting workers, freelancers, shops, and clients. We aim to organize and facilitate access to professional services across Sudan safely and reliably.'**
  String get sudanFreeIsTheFirstIntegrated;

  /// No description provided for @forServiceProviders.
  ///
  /// In en, this message translates to:
  /// **'👷 For Service Providers'**
  String get forServiceProviders;

  /// No description provided for @dedicatedSpaceToShowcaseYourSkillsn.
  ///
  /// In en, this message translates to:
  /// **'• Dedicated space to showcase your skills.\\n• Account verification for higher trust 🤝.\\n• Professional rating system upgrading your rank.\\n• Direct job requests and free negotiation.\\n• Create in-app contracts to secure rights.\\n• Full portfolio to display past achievements.'**
  String get dedicatedSpaceToShowcaseYourSkillsn;

  /// No description provided for @forClients1.
  ///
  /// In en, this message translates to:
  /// **'👤 For Clients'**
  String get forClients1;

  /// No description provided for @smartSearchForTheRightProvider.
  ///
  /// In en, this message translates to:
  /// **'• Smart search for the right provider in your area.\\n• Reliable review system reflecting quality.\\n• Ability to post a \"job request\" for bids.\\n• Direct communication via app, phone, or official contract.'**
  String get smartSearchForTheRightProvider;

  /// No description provided for @premiumFeatures.
  ///
  /// In en, this message translates to:
  /// **'✨ Premium Features'**
  String get premiumFeatures;

  /// No description provided for @mapExplorerAFastLocallyCached.
  ///
  /// In en, this message translates to:
  /// **'Map Explorer: A fast, locally cached smart map to find nearby service providers and shops without consuming much data.'**
  String get mapExplorerAFastLocallyCached;

  /// No description provided for @unifiedFavoritesOnePlaceToSave.
  ///
  /// In en, this message translates to:
  /// **'Unified Favorites: One place to save great products, as well as favorite freelancers and peers to quickly access them later.'**
  String get unifiedFavoritesOnePlaceToSave;

  /// No description provided for @ourVision.
  ///
  /// In en, this message translates to:
  /// **'🌍 Our Vision'**
  String get ourVision;

  /// No description provided for @weStriveToBuildACohesive.
  ///
  /// In en, this message translates to:
  /// **'We strive to build a cohesive Sudanese professional community that supports youth in marketing themselves and protects clients through transparent and fair continuous ratings.'**
  String get weStriveToBuildACohesive;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @showOnMap.
  ///
  /// In en, this message translates to:
  /// **'Show on Map'**
  String get showOnMap;

  /// No description provided for @glassmorphismPerformance.
  ///
  /// In en, this message translates to:
  /// **'Glassmorphism (Performance)'**
  String get glassmorphismPerformance;

  /// No description provided for @enabledAppWillCloseToApply.
  ///
  /// In en, this message translates to:
  /// **'Enabled (App will close to apply changes)'**
  String get enabledAppWillCloseToApply;

  /// No description provided for @disabledAppWillCloseToApply.
  ///
  /// In en, this message translates to:
  /// **'Disabled (App will close to apply changes)'**
  String get disabledAppWillCloseToApply;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @accountVerification.
  ///
  /// In en, this message translates to:
  /// **'Account Verification'**
  String get accountVerification;

  /// No description provided for @verifiedHandshakeIconShowsBesideYour.
  ///
  /// In en, this message translates to:
  /// **'Verified — Handshake icon shows beside your name'**
  String get verifiedHandshakeIconShowsBesideYour;

  /// No description provided for @comingSoonHandshakeIconBesideYour.
  ///
  /// In en, this message translates to:
  /// **'Coming soon — Handshake icon beside your name'**
  String get comingSoonHandshakeIconBesideYour;

  /// No description provided for @manageVerificationsStats.
  ///
  /// In en, this message translates to:
  /// **'Manage verifications & stats'**
  String get manageVerificationsStats;

  /// No description provided for @myAgreements.
  ///
  /// In en, this message translates to:
  /// **'My Agreements'**
  String get myAgreements;

  /// No description provided for @manageContractsAndTrackProgress.
  ///
  /// In en, this message translates to:
  /// **'Manage contracts and track progress'**
  String get manageContractsAndTrackProgress;

  /// No description provided for @safetySecurity.
  ///
  /// In en, this message translates to:
  /// **'Safety & Security'**
  String get safetySecurity;

  /// No description provided for @safetyTips.
  ///
  /// In en, this message translates to:
  /// **'🛡️ Safety Tips'**
  String get safetyTips;

  /// No description provided for @protectYourselfFromFraud.
  ///
  /// In en, this message translates to:
  /// **'Protect yourself from fraud'**
  String get protectYourselfFromFraud;

  /// No description provided for @myInterests.
  ///
  /// In en, this message translates to:
  /// **'My Interests'**
  String get myInterests;

  /// No description provided for @setInterestsToPersonalizeContent.
  ///
  /// In en, this message translates to:
  /// **'Set interests to personalize content'**
  String get setInterestsToPersonalizeContent;

  /// No description provided for @connectWithUs.
  ///
  /// In en, this message translates to:
  /// **'Connect with Us'**
  String get connectWithUs;

  /// No description provided for @whatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsapp;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// No description provided for @facebook.
  ///
  /// In en, this message translates to:
  /// **'Facebook'**
  String get facebook;

  /// No description provided for @telegram.
  ///
  /// In en, this message translates to:
  /// **'Telegram'**
  String get telegram;

  /// No description provided for @website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// No description provided for @shareApp.
  ///
  /// In en, this message translates to:
  /// **'Share App'**
  String get shareApp;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'📱 About App'**
  String get aboutApp;

  /// No description provided for @whatDoYouWantToDo.
  ///
  /// In en, this message translates to:
  /// **'What do you want to do?'**
  String get whatDoYouWantToDo;

  /// No description provided for @youCanLogoutAndReturnLater.
  ///
  /// In en, this message translates to:
  /// **'You can logout and return later, or permanently delete your account and data from the app.'**
  String get youCanLogoutAndReturnLater;

  /// No description provided for @deleteAccountPermanently.
  ///
  /// In en, this message translates to:
  /// **'Delete Account Permanently'**
  String get deleteAccountPermanently;

  /// No description provided for @deleteAccountRequest.
  ///
  /// In en, this message translates to:
  /// **'Delete Account Request'**
  String get deleteAccountRequest;

  /// No description provided for @forSecurityReasonsAndToProtect.
  ///
  /// In en, this message translates to:
  /// **'For security reasons and to protect all users, deletion requests are reviewed by admin. Please state your reason. You will be logged out until the deletion is complete.'**
  String get forSecurityReasonsAndToProtect;

  /// No description provided for @reasonOptionalButSpeedsUpThe.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional but speeds up the process)'**
  String get reasonOptionalButSpeedsUpThe;

  /// No description provided for @deletionRequestSentSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Deletion request sent successfully'**
  String get deletionRequestSentSuccessfully;

  /// No description provided for @errorOccurredTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Error occurred, try again'**
  String get errorOccurredTryAgain;

  /// No description provided for @confirmRequest.
  ///
  /// In en, this message translates to:
  /// **'Confirm Request'**
  String get confirmRequest;

  /// No description provided for @interestsSaved.
  ///
  /// In en, this message translates to:
  /// **'Interests saved ✅'**
  String get interestsSaved;

  /// No description provided for @chooseToPersonalizeYourFeed.
  ///
  /// In en, this message translates to:
  /// **'Choose to personalize your feed'**
  String get chooseToPersonalizeYourFeed;

  /// No description provided for @services.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get services;

  /// No description provided for @shopTypes.
  ///
  /// In en, this message translates to:
  /// **'Shop Types'**
  String get shopTypes;

  /// No description provided for @saveInterests.
  ///
  /// In en, this message translates to:
  /// **'Save Interests'**
  String get saveInterests;

  /// No description provided for @updateMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Update My Location'**
  String get updateMyLocation;

  /// No description provided for @updatingNow.
  ///
  /// In en, this message translates to:
  /// **'Updating now...'**
  String get updatingNow;

  /// No description provided for @captureYourCurrentLocationForThe.
  ///
  /// In en, this message translates to:
  /// **'Capture your current location for the map'**
  String get captureYourCurrentLocationForThe;

  /// No description provided for @pleaseEnableLocationServices.
  ///
  /// In en, this message translates to:
  /// **'Please enable Location services'**
  String get pleaseEnableLocationServices;

  /// No description provided for @locationPermissionsArePermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permissions are permanently denied'**
  String get locationPermissionsArePermanentlyDenied;

  /// No description provided for @locationUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Location updated successfully!'**
  String get locationUpdatedSuccessfully;

  /// No description provided for @errorUpdatingLocation.
  ///
  /// In en, this message translates to:
  /// **'Error updating location'**
  String get errorUpdatingLocation;

  /// No description provided for @failedToCaptureLocation.
  ///
  /// In en, this message translates to:
  /// **'Failed to capture location'**
  String get failedToCaptureLocation;

  /// No description provided for @policiesTerms.
  ///
  /// In en, this message translates to:
  /// **'Policies & Terms'**
  String get policiesTerms;

  /// No description provided for @usagePoliciesStandards.
  ///
  /// In en, this message translates to:
  /// **'Usage Policies & Standards'**
  String get usagePoliciesStandards;

  /// No description provided for @importantWarningsTerms.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Important Warnings & Terms'**
  String get importantWarningsTerms;

  /// No description provided for @thisAppIsStrictlyForLegitimate.
  ///
  /// In en, this message translates to:
  /// **'This app is strictly for legitimate and safe job and service searching.'**
  String get thisAppIsStrictlyForLegitimate;

  /// No description provided for @postingOffensiveContentOrEngagingIn.
  ///
  /// In en, this message translates to:
  /// **'Posting offensive content or engaging in unethical behavior is strictly prohibited and will result in an immediate permanent ban.'**
  String get postingOffensiveContentOrEngagingIn;

  /// No description provided for @theAppIsAMediumTo.
  ///
  /// In en, this message translates to:
  /// **'The app is a medium to connect clients with freelancers and shops. We hold no legal or financial responsibility for agreements made.'**
  String get theAppIsAMediumTo;

  /// No description provided for @doNotPayAnyMoneyIn.
  ///
  /// In en, this message translates to:
  /// **'Do not pay any money in advance before receiving the service or verifying credibility.'**
  String get doNotPayAnyMoneyIn;

  /// No description provided for @whenAgreeingToMeetEnsureIt.
  ///
  /// In en, this message translates to:
  /// **'When agreeing to meet, ensure it is in a public and safe place.'**
  String get whenAgreeingToMeetEnsureIt;

  /// No description provided for @alwaysDealWithVerifiedAccountsWith.
  ///
  /// In en, this message translates to:
  /// **'Always deal with verified accounts (with the handshake symbol 🤝) for higher reliability and safer transactions.'**
  String get alwaysDealWithVerifiedAccountsWith;

  /// No description provided for @ratingTrustSystem.
  ///
  /// In en, this message translates to:
  /// **'🏆 Rating & Trust System'**
  String get ratingTrustSystem;

  /// No description provided for @starsAwardedInReviewsUpgradeYour.
  ///
  /// In en, this message translates to:
  /// **'Stars awarded in reviews upgrade your rank from standard to professional, increasing your visibility.'**
  String get starsAwardedInReviewsUpgradeYour;

  /// No description provided for @theRatingSystemPreventsManipulationOnly.
  ///
  /// In en, this message translates to:
  /// **'The rating system prevents manipulation. Only the first rating from each client counts towards stars.'**
  String get theRatingSystemPreventsManipulationOnly;

  /// No description provided for @privacyDataDeletion.
  ///
  /// In en, this message translates to:
  /// **'🔒 Privacy & Data Deletion'**
  String get privacyDataDeletion;

  /// No description provided for @yourPersonalDataNameLocationPhone.
  ///
  /// In en, this message translates to:
  /// **'Your personal data (name, location, phone) is used exclusively to connect you with clients. We do not share it with third parties.'**
  String get yourPersonalDataNameLocationPhone;

  /// No description provided for @mapControlAnyFreelancerOrShop.
  ///
  /// In en, this message translates to:
  /// **'Map Control: Any freelancer or shop can hide their location entirely from the public map at any time via settings. When disabled, your location is immediately hidden to protect your privacy.'**
  String get mapControlAnyFreelancerOrShop;

  /// No description provided for @youHaveTheRightToRequest.
  ///
  /// In en, this message translates to:
  /// **'You have the right to request account deletion. Upon request, it is reviewed for security reasons, then all your data including favorites and location is permanently deleted.'**
  String get youHaveTheRightToRequest;

  /// No description provided for @usingTheAppMeansYourExplicit.
  ///
  /// In en, this message translates to:
  /// **'Using the app means your explicit agreement to these policies'**
  String get usingTheAppMeansYourExplicit;

  /// No description provided for @reportReceived.
  ///
  /// In en, this message translates to:
  /// **'Report Received 🛡️'**
  String get reportReceived;

  /// No description provided for @reportSubmittedSuccessfullyAndWillBe.
  ///
  /// In en, this message translates to:
  /// **'Report submitted successfully and will be reviewed'**
  String get reportSubmittedSuccessfullyAndWillBe;

  /// No description provided for @failedToSubmitReportPleaseTry.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit report. Please try again.'**
  String get failedToSubmitReportPleaseTry;

  /// No description provided for @reportUser.
  ///
  /// In en, this message translates to:
  /// **'Report User'**
  String get reportUser;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @explainTheIssueInDetail.
  ///
  /// In en, this message translates to:
  /// **'Explain the issue in detail...'**
  String get explainTheIssueInDetail;

  /// No description provided for @thisFieldIsRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get thisFieldIsRequired;

  /// No description provided for @pleaseProvideMoreDetails.
  ///
  /// In en, this message translates to:
  /// **'Please provide more details'**
  String get pleaseProvideMoreDetails;

  /// No description provided for @addScreenshotOptional.
  ///
  /// In en, this message translates to:
  /// **'Add screenshot (optional)'**
  String get addScreenshotOptional;

  /// No description provided for @userPhoneNumberWillBeAutomatically.
  ///
  /// In en, this message translates to:
  /// **'User phone number will be automatically attached.'**
  String get userPhoneNumberWillBeAutomatically;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// No description provided for @beauty.
  ///
  /// In en, this message translates to:
  /// **'Beauty'**
  String get beauty;

  /// No description provided for @onlineStore.
  ///
  /// In en, this message translates to:
  /// **'Online Store'**
  String get onlineStore;

  /// No description provided for @localStore.
  ///
  /// In en, this message translates to:
  /// **'Local Store'**
  String get localStore;

  /// No description provided for @sudanfree.
  ///
  /// In en, this message translates to:
  /// **'SudanFree'**
  String get sudanfree;

  /// No description provided for @searchSudanfree.
  ///
  /// In en, this message translates to:
  /// **'Search SudanFree...'**
  String get searchSudanfree;

  /// No description provided for @sponsored.
  ///
  /// In en, this message translates to:
  /// **'Sponsored'**
  String get sponsored;

  /// No description provided for @strNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get strNew;

  /// No description provided for @top.
  ///
  /// In en, this message translates to:
  /// **'Top'**
  String get top;

  /// No description provided for @topRated.
  ///
  /// In en, this message translates to:
  /// **'Top Rated'**
  String get topRated;

  /// No description provided for @nearest.
  ///
  /// In en, this message translates to:
  /// **'Nearest'**
  String get nearest;

  /// No description provided for @servicesNearYou.
  ///
  /// In en, this message translates to:
  /// **'Services Near You'**
  String get servicesNearYou;

  /// No description provided for @shopsNearYou.
  ///
  /// In en, this message translates to:
  /// **'Shops Near You'**
  String get shopsNearYou;

  /// No description provided for @noDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noDataAvailable;

  /// No description provided for @artisan.
  ///
  /// In en, this message translates to:
  /// **'Artisan'**
  String get artisan;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @squads.
  ///
  /// In en, this message translates to:
  /// **'Squads'**
  String get squads;

  /// No description provided for @requests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get requests;

  /// No description provided for @editSquad.
  ///
  /// In en, this message translates to:
  /// **'Edit Squad'**
  String get editSquad;

  /// No description provided for @createSquad.
  ///
  /// In en, this message translates to:
  /// **'Create Squad'**
  String get createSquad;

  /// No description provided for @squadName.
  ///
  /// In en, this message translates to:
  /// **'Squad Name'**
  String get squadName;

  /// No description provided for @egIntegratedBuildersSquad.
  ///
  /// In en, this message translates to:
  /// **'e.g., Integrated Builders Squad'**
  String get egIntegratedBuildersSquad;

  /// No description provided for @strRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get strRequired;

  /// No description provided for @squadDescription.
  ///
  /// In en, this message translates to:
  /// **'Squad Description'**
  String get squadDescription;

  /// No description provided for @describeTheSquadSpecialization.
  ///
  /// In en, this message translates to:
  /// **'Describe the squad specialization...'**
  String get describeTheSquadSpecialization;

  /// No description provided for @squadCategory.
  ///
  /// In en, this message translates to:
  /// **'Squad Category'**
  String get squadCategory;

  /// No description provided for @selectMainSpecialization.
  ///
  /// In en, this message translates to:
  /// **'Select main specialization'**
  String get selectMainSpecialization;

  /// No description provided for @servicesSpecialtiesOptional.
  ///
  /// In en, this message translates to:
  /// **'Services & Specialties (Optional)'**
  String get servicesSpecialtiesOptional;

  /// No description provided for @enterSkillsSeparatedByComma.
  ///
  /// In en, this message translates to:
  /// **'Enter skills separated by comma (,)'**
  String get enterSkillsSeparatedByComma;

  /// No description provided for @ifLeftEmptyMembersSkillsWill.
  ///
  /// In en, this message translates to:
  /// **'* If left empty, members skills will be displayed automatically.'**
  String get ifLeftEmptyMembersSkillsWill;

  /// No description provided for @squadLocationOptional.
  ///
  /// In en, this message translates to:
  /// **'Squad Location (Optional)'**
  String get squadLocationOptional;

  /// No description provided for @state.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get state;

  /// No description provided for @locality.
  ///
  /// In en, this message translates to:
  /// **'Locality'**
  String get locality;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @exploreSquads.
  ///
  /// In en, this message translates to:
  /// **'Explore Squads'**
  String get exploreSquads;

  /// No description provided for @searchSquads.
  ///
  /// In en, this message translates to:
  /// **'Search squads...'**
  String get searchSquads;

  /// No description provided for @noSquadsFound.
  ///
  /// In en, this message translates to:
  /// **'No squads found'**
  String get noSquadsFound;

  /// No description provided for @busy.
  ///
  /// In en, this message translates to:
  /// **'Busy'**
  String get busy;

  /// No description provided for @searchForShopShowroom.
  ///
  /// In en, this message translates to:
  /// **'Search for shop, showroom...'**
  String get searchForShopShowroom;

  /// No description provided for @selectLocation.
  ///
  /// In en, this message translates to:
  /// **'Select Location'**
  String get selectLocation;

  /// No description provided for @allStates.
  ///
  /// In en, this message translates to:
  /// **'All States'**
  String get allStates;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// No description provided for @recommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get recommended;

  /// No description provided for @enableLocationInYourProfileFirst.
  ///
  /// In en, this message translates to:
  /// **'Enable location in your profile first'**
  String get enableLocationInYourProfileFirst;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @tryDifferentKeywordsOrCheckSpelling.
  ///
  /// In en, this message translates to:
  /// **'Try different keywords or check spelling'**
  String get tryDifferentKeywordsOrCheckSpelling;

  /// No description provided for @errorFetchingData.
  ///
  /// In en, this message translates to:
  /// **'Error fetching data'**
  String get errorFetchingData;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closed;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @enterYourEmailAndWeWill.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we will send you a password reset link.'**
  String get enterYourEmailAndWeWill;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @resetLinkSentToYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Reset link sent to your email ✉️'**
  String get resetLinkSentToYourEmail;

  /// No description provided for @dynamicString.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get dynamicString;

  /// No description provided for @emailIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailIsRequired;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get invalidEmail;

  /// No description provided for @passwordIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordIsRequired;

  /// No description provided for @noInternetConnectionPleaseCheckYour.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please check your network and try again.'**
  String get noInternetConnectionPleaseCheckYour;

  /// No description provided for @signInCanceled.
  ///
  /// In en, this message translates to:
  /// **'Sign in canceled'**
  String get signInCanceled;

  /// No description provided for @facebookAuthenticationWillBeActivatedSoon.
  ///
  /// In en, this message translates to:
  /// **'Facebook authentication will be activated soon'**
  String get facebookAuthenticationWillBeActivatedSoon;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithFacebook.
  ///
  /// In en, this message translates to:
  /// **'Continue with Facebook'**
  String get continueWithFacebook;

  /// No description provided for @termsOfUseAndPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use and Privacy'**
  String get termsOfUseAndPrivacy;

  /// No description provided for @byClickingAgreeYouConfirmThat.
  ///
  /// In en, this message translates to:
  /// **'By clicking \"Agree\", you confirm that you have read and agreed to our Terms of Use and Privacy Policy.'**
  String get byClickingAgreeYouConfirmThat;

  /// No description provided for @agree.
  ///
  /// In en, this message translates to:
  /// **'Agree'**
  String get agree;

  /// No description provided for @welcomeToSudanfree.
  ///
  /// In en, this message translates to:
  /// **'Welcome to SudanFree!'**
  String get welcomeToSudanfree;

  /// No description provided for @createYourAccountToStartYour.
  ///
  /// In en, this message translates to:
  /// **'Create your account to start your freelance journey'**
  String get createYourAccountToStartYour;

  /// No description provided for @enterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterYourPassword;

  /// No description provided for @passwordMustBeAtLeast6.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMustBeAtLeast6;

  /// No description provided for @reenterPassword.
  ///
  /// In en, this message translates to:
  /// **'Re-enter password'**
  String get reenterPassword;

  /// No description provided for @confirmPasswordIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Confirm password is required'**
  String get confirmPasswordIsRequired;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @byRegisteringYouAgreeToThe.
  ///
  /// In en, this message translates to:
  /// **'By registering, you agree to the Terms of Use and Privacy Policy'**
  String get byRegisteringYouAgreeToThe;

  /// No description provided for @youCannotSwitchToANew.
  ///
  /// In en, this message translates to:
  /// **'You cannot switch to a new provider type to protect your reviews. You can only be a Client or your original profession.'**
  String get youCannotSwitchToANew;

  /// No description provided for @verifyingLocationViaGps.
  ///
  /// In en, this message translates to:
  /// **'Verifying location via GPS...'**
  String get verifyingLocationViaGps;

  /// No description provided for @couldNotAccessLocationServicesMake.
  ///
  /// In en, this message translates to:
  /// **'Could not access location services. Make sure GPS and permissions are enabled.'**
  String get couldNotAccessLocationServicesMake;

  /// No description provided for @verifiedSuccessfullyYouAreInSudan.
  ///
  /// In en, this message translates to:
  /// **'✅ Verified successfully! You are in Sudan.'**
  String get verifiedSuccessfullyYouAreInSudan;

  /// No description provided for @itAppearsYouAreOutsideSudan.
  ///
  /// In en, this message translates to:
  /// **'It appears you are outside Sudan. You can register as a client.'**
  String get itAppearsYouAreOutsideSudan;

  /// No description provided for @errorVerifyingLocation.
  ///
  /// In en, this message translates to:
  /// **'Error verifying location'**
  String get errorVerifyingLocation;

  /// No description provided for @sorryYouCanSelectUpTo.
  ///
  /// In en, this message translates to:
  /// **'Sorry, you can select up to 2 categories'**
  String get sorryYouCanSelectUpTo;

  /// No description provided for @sorryYouCanOnlyAddOne.
  ///
  /// In en, this message translates to:
  /// **'Sorry, you can only add one custom shop type'**
  String get sorryYouCanOnlyAddOne;

  /// No description provided for @customShopType.
  ///
  /// In en, this message translates to:
  /// **'Custom Shop Type'**
  String get customShopType;

  /// No description provided for @customJobTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom Job Title'**
  String get customJobTitle;

  /// No description provided for @typeYourShopCategoryIfNot.
  ///
  /// In en, this message translates to:
  /// **'Type your shop category if not listed'**
  String get typeYourShopCategoryIfNot;

  /// No description provided for @typeYourProfessionIfNotListed.
  ///
  /// In en, this message translates to:
  /// **'Type your profession if not listed'**
  String get typeYourProfessionIfNotListed;

  /// No description provided for @egGiftShopPerfumes.
  ///
  /// In en, this message translates to:
  /// **'e.g. Gift Shop, Perfumes...'**
  String get egGiftShopPerfumes;

  /// No description provided for @egCarpenterBlacksmith.
  ///
  /// In en, this message translates to:
  /// **'e.g. Carpenter, Blacksmith...'**
  String get egCarpenterBlacksmith;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @pleaseTypeFirst.
  ///
  /// In en, this message translates to:
  /// **'Please type first'**
  String get pleaseTypeFirst;

  /// No description provided for @thisTitleIsAlreadyAdded.
  ///
  /// In en, this message translates to:
  /// **'This title is already added'**
  String get thisTitleIsAlreadyAdded;

  /// No description provided for @failedToSaveProfilePleaseTry.
  ///
  /// In en, this message translates to:
  /// **'Failed to save profile. Please try again.'**
  String get failedToSaveProfilePleaseTry;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @completeProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete Profile'**
  String get completeProfile;

  /// No description provided for @pleaseWaitForLocationVerificationTo.
  ///
  /// In en, this message translates to:
  /// **'Please wait for location verification to complete'**
  String get pleaseWaitForLocationVerificationTo;

  /// No description provided for @selectAnAccountType.
  ///
  /// In en, this message translates to:
  /// **'Select an account type'**
  String get selectAnAccountType;

  /// No description provided for @pleaseEnterAValidRealName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid real name (letters only)'**
  String get pleaseEnterAValidRealName;

  /// No description provided for @aValidPhoneNumberIsRequired.
  ///
  /// In en, this message translates to:
  /// **'A valid phone number is required'**
  String get aValidPhoneNumberIsRequired;

  /// No description provided for @hourlyRateIsRequiredForService.
  ///
  /// In en, this message translates to:
  /// **'Hourly rate is required for service providers'**
  String get hourlyRateIsRequiredForService;

  /// No description provided for @stateMustBeSelectedForGeneral.
  ///
  /// In en, this message translates to:
  /// **'State must be selected for general services and shops'**
  String get stateMustBeSelectedForGeneral;

  /// No description provided for @localityMustBeSelected.
  ///
  /// In en, this message translates to:
  /// **'Locality must be selected'**
  String get localityMustBeSelected;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @pleaseWaitWhileLocationIsBeing.
  ///
  /// In en, this message translates to:
  /// **'Please wait while location is being detected'**
  String get pleaseWaitWhileLocationIsBeing;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @couldNotDetectYourLocationAutomatically.
  ///
  /// In en, this message translates to:
  /// **'Could not detect your location automatically. Please verify via GPS to unlock all account types.'**
  String get couldNotDetectYourLocationAutomatically;

  /// No description provided for @yourConnectionShowsYouAreOutside.
  ///
  /// In en, this message translates to:
  /// **'Your connection shows you are outside Sudan. You can only register as \"Client\".\\nIf you are in Sudan, verify via GPS.'**
  String get yourConnectionShowsYouAreOutside;

  /// No description provided for @verifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying...'**
  String get verifying;

  /// No description provided for @verifyMyLocationViaGps.
  ///
  /// In en, this message translates to:
  /// **'Verify my location via GPS'**
  String get verifyMyLocationViaGps;

  /// No description provided for @retryDetection.
  ///
  /// In en, this message translates to:
  /// **'Retry Detection'**
  String get retryDetection;

  /// No description provided for @craftServiceProvider.
  ///
  /// In en, this message translates to:
  /// **'Craft Service Provider'**
  String get craftServiceProvider;

  /// No description provided for @electricianPlumberCarpenterEtc.
  ///
  /// In en, this message translates to:
  /// **'Electrician, Plumber, Carpenter, etc.'**
  String get electricianPlumberCarpenterEtc;

  /// No description provided for @techServiceProvider.
  ///
  /// In en, this message translates to:
  /// **'Tech Service Provider'**
  String get techServiceProvider;

  /// No description provided for @programmerDesignerVideoEditorOrRemote.
  ///
  /// In en, this message translates to:
  /// **'Programmer, Designer, Video Editor, or Remote Worker'**
  String get programmerDesignerVideoEditorOrRemote;

  /// No description provided for @privateServiceProvider.
  ///
  /// In en, this message translates to:
  /// **'Private Service Provider'**
  String get privateServiceProvider;

  /// No description provided for @privateTutorLawyerChefTranslatorTour.
  ///
  /// In en, this message translates to:
  /// **'Private Tutor, Lawyer, Chef, Translator, Tour Guide, etc.'**
  String get privateTutorLawyerChefTranslatorTour;

  /// No description provided for @shopGalleryOwner.
  ///
  /// In en, this message translates to:
  /// **'Shop / Gallery Owner'**
  String get shopGalleryOwner;

  /// No description provided for @iOwnAStoregalleryAndDisplay.
  ///
  /// In en, this message translates to:
  /// **'I own a store/gallery and display my products'**
  String get iOwnAStoregalleryAndDisplay;

  /// No description provided for @iAmLookingForWorkersFreelancers.
  ///
  /// In en, this message translates to:
  /// **'I am looking for workers, freelancers, and products (Browse and Interact)'**
  String get iAmLookingForWorkersFreelancers;

  /// No description provided for @basicInformation.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get basicInformation;

  /// No description provided for @shopName.
  ///
  /// In en, this message translates to:
  /// **'Shop Name'**
  String get shopName;

  /// No description provided for @enterShopName.
  ///
  /// In en, this message translates to:
  /// **'Enter shop name'**
  String get enterShopName;

  /// No description provided for @enterYourFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get enterYourFullName;

  /// No description provided for @whatsappPhone.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp / Phone'**
  String get whatsappPhone;

  /// No description provided for @shopDescription.
  ///
  /// In en, this message translates to:
  /// **'Shop Description'**
  String get shopDescription;

  /// No description provided for @writeADescriptionForYourShop.
  ///
  /// In en, this message translates to:
  /// **'Write a description for your shop...'**
  String get writeADescriptionForYourShop;

  /// No description provided for @writeAShortBioAboutYourself.
  ///
  /// In en, this message translates to:
  /// **'Write a short bio about yourself...'**
  String get writeAShortBioAboutYourself;

  /// No description provided for @neighborhoodStreet.
  ///
  /// In en, this message translates to:
  /// **'Neighborhood / Street'**
  String get neighborhoodStreet;

  /// No description provided for @enterYourNeighborhoodName.
  ///
  /// In en, this message translates to:
  /// **'Enter your neighborhood name...'**
  String get enterYourNeighborhoodName;

  /// No description provided for @whatAmountSatisfiesYouFornoneHour.
  ///
  /// In en, this message translates to:
  /// **'What amount satisfies you for\\none hour of continuous work?'**
  String get whatAmountSatisfiesYouFornoneHour;

  /// No description provided for @sdghr.
  ///
  /// In en, this message translates to:
  /// **'SDG/hr'**
  String get sdghr;

  /// No description provided for @openingTime.
  ///
  /// In en, this message translates to:
  /// **'Opening Time'**
  String get openingTime;

  /// No description provided for @closingTime.
  ///
  /// In en, this message translates to:
  /// **'Closing Time'**
  String get closingTime;

  /// No description provided for @settingLocationIsOptionalForYour.
  ///
  /// In en, this message translates to:
  /// **'Setting location is optional for your account, you can skip it if you want.'**
  String get settingLocationIsOptionalForYour;

  /// No description provided for @detecting.
  ///
  /// In en, this message translates to:
  /// **'Detecting...'**
  String get detecting;

  /// No description provided for @autoDetectMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Auto Detect My Location'**
  String get autoDetectMyLocation;

  /// No description provided for @selectState.
  ///
  /// In en, this message translates to:
  /// **'Select state'**
  String get selectState;

  /// No description provided for @selectLocality.
  ///
  /// In en, this message translates to:
  /// **'Select locality'**
  String get selectLocality;

  /// No description provided for @workFields.
  ///
  /// In en, this message translates to:
  /// **'Work Fields'**
  String get workFields;

  /// No description provided for @chooseYourWorkFields.
  ///
  /// In en, this message translates to:
  /// **'Choose your work fields'**
  String get chooseYourWorkFields;

  /// No description provided for @customTitles.
  ///
  /// In en, this message translates to:
  /// **'Custom titles:'**
  String get customTitles;

  /// No description provided for @addCustomJobTitle.
  ///
  /// In en, this message translates to:
  /// **'Add custom job title'**
  String get addCustomJobTitle;

  /// No description provided for @shopCategory1.
  ///
  /// In en, this message translates to:
  /// **'Shop Category'**
  String get shopCategory1;

  /// No description provided for @chooseYourShopCategory.
  ///
  /// In en, this message translates to:
  /// **'Choose your shop category'**
  String get chooseYourShopCategory;

  /// No description provided for @customType.
  ///
  /// In en, this message translates to:
  /// **'Custom type:'**
  String get customType;

  /// No description provided for @addCustomShopType.
  ///
  /// In en, this message translates to:
  /// **'Add custom shop type'**
  String get addCustomShopType;

  /// No description provided for @yourInterests.
  ///
  /// In en, this message translates to:
  /// **'Your Interests'**
  String get yourInterests;

  /// No description provided for @makeSureToAddYourLocation.
  ///
  /// In en, this message translates to:
  /// **'Make sure to add your location in the previous step so we can connect you with the nearest service providers in your area!'**
  String get makeSureToAddYourLocation;

  /// No description provided for @shopTypesYouAreInterestedIn.
  ///
  /// In en, this message translates to:
  /// **'🏪 Shop types you are interested in'**
  String get shopTypesYouAreInterestedIn;

  /// No description provided for @weWillShowTheseTypesFirst.
  ///
  /// In en, this message translates to:
  /// **'We will show these types first in the shops list'**
  String get weWillShowTheseTypesFirst;

  /// No description provided for @servicesYouNeed.
  ///
  /// In en, this message translates to:
  /// **'🔧 Services you need'**
  String get servicesYouNeed;

  /// No description provided for @weWillHighlightProvidersOfThese.
  ///
  /// In en, this message translates to:
  /// **'We will highlight providers of these services on the main screen'**
  String get weWillHighlightProvidersOfThese;

  /// No description provided for @togetherWeBuildTheFuture.
  ///
  /// In en, this message translates to:
  /// **'Together we build the future'**
  String get togetherWeBuildTheFuture;

  /// No description provided for @thankYouForYourSupport.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your support!'**
  String get thankYouForYourSupport;

  /// No description provided for @weAppreciateYourSupportForThis.
  ///
  /// In en, this message translates to:
  /// **'We appreciate your support for this generation of creators and craftsmen.\\n\\nFor a safe community, please report any suspicious pages or offers immediately.'**
  String get weAppreciateYourSupportForThis;

  /// No description provided for @verificationOptional.
  ///
  /// In en, this message translates to:
  /// **'Verification (Optional)'**
  String get verificationOptional;

  /// No description provided for @verifyYourAccountToIncreaseTrust.
  ///
  /// In en, this message translates to:
  /// **'Verify your account to increase trust'**
  String get verifyYourAccountToIncreaseTrust;

  /// No description provided for @youCanUploadYourProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'You can upload your profile photo and verify your identity from Settings after creating your account to get the handshake verification symbol 🤝 next to your name.'**
  String get youCanUploadYourProfilePhoto;

  /// No description provided for @goToVerificationPage.
  ///
  /// In en, this message translates to:
  /// **'Go to Verification Page'**
  String get goToVerificationPage;

  /// No description provided for @am.
  ///
  /// In en, this message translates to:
  /// **'AM'**
  String get am;

  /// No description provided for @pm.
  ///
  /// In en, this message translates to:
  /// **'PM'**
  String get pm;

  /// No description provided for @leaveSquad.
  ///
  /// In en, this message translates to:
  /// **'Leave Squad'**
  String get leaveSquad;

  /// No description provided for @areYouSureYouWantTo.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave?'**
  String get areYouSureYouWantTo;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @removeMember.
  ///
  /// In en, this message translates to:
  /// **'Remove Member'**
  String get removeMember;

  /// No description provided for @areYouSureYouWantTo1.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this member?'**
  String get areYouSureYouWantTo1;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @transferLeadership.
  ///
  /// In en, this message translates to:
  /// **'Transfer Leadership'**
  String get transferLeadership;

  /// No description provided for @areYouSureYouWantTo2.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to transfer leadership to this member? You will lose leader privileges.'**
  String get areYouSureYouWantTo2;

  /// No description provided for @confirmTransfer.
  ///
  /// In en, this message translates to:
  /// **'Confirm Transfer'**
  String get confirmTransfer;

  /// No description provided for @disbandSquad.
  ///
  /// In en, this message translates to:
  /// **'Disband Squad'**
  String get disbandSquad;

  /// No description provided for @areYouSureThisCannotBe.
  ///
  /// In en, this message translates to:
  /// **'Are you sure? This cannot be undone and the squad will be deleted.'**
  String get areYouSureThisCannotBe;

  /// No description provided for @disbandForever.
  ///
  /// In en, this message translates to:
  /// **'Disband Forever'**
  String get disbandForever;

  /// No description provided for @noPartnersToInvite.
  ///
  /// In en, this message translates to:
  /// **'No partners to invite'**
  String get noPartnersToInvite;

  /// No description provided for @invitePartnersToSquad.
  ///
  /// In en, this message translates to:
  /// **'Invite Partners to Squad'**
  String get invitePartnersToSquad;

  /// No description provided for @noPartners.
  ///
  /// In en, this message translates to:
  /// **'No partners'**
  String get noPartners;

  /// No description provided for @invite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get invite;

  /// No description provided for @userIsAlreadyInASquad.
  ///
  /// In en, this message translates to:
  /// **'User is already in a squad.'**
  String get userIsAlreadyInASquad;

  /// No description provided for @inviteSentSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Invite sent successfully!'**
  String get inviteSentSuccessfully;

  /// No description provided for @squadDashboard.
  ///
  /// In en, this message translates to:
  /// **'Squad Dashboard'**
  String get squadDashboard;

  /// No description provided for @youAreTheLeader.
  ///
  /// In en, this message translates to:
  /// **'You are the Leader'**
  String get youAreTheLeader;

  /// No description provided for @youAreAMember.
  ///
  /// In en, this message translates to:
  /// **'You are a Member'**
  String get youAreAMember;

  /// No description provided for @squadManagement.
  ///
  /// In en, this message translates to:
  /// **'Squad Management'**
  String get squadManagement;

  /// No description provided for @editSquadDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit Squad Details'**
  String get editSquadDetails;

  /// No description provided for @changeNameDescriptionOrImage.
  ///
  /// In en, this message translates to:
  /// **'Change name, description, or image'**
  String get changeNameDescriptionOrImage;

  /// No description provided for @availableForHire.
  ///
  /// In en, this message translates to:
  /// **'Available for hire'**
  String get availableForHire;

  /// No description provided for @squadIsAvailableForNewRequests.
  ///
  /// In en, this message translates to:
  /// **'Squad is available for new requests'**
  String get squadIsAvailableForNewRequests;

  /// No description provided for @squadIsCurrentlyBusy.
  ///
  /// In en, this message translates to:
  /// **'Squad is currently busy'**
  String get squadIsCurrentlyBusy;

  /// No description provided for @anErrorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get anErrorOccurred;

  /// No description provided for @addProjectToPortfolio.
  ///
  /// In en, this message translates to:
  /// **'Add Project to Portfolio'**
  String get addProjectToPortfolio;

  /// No description provided for @uploadPreviousSquadWorks.
  ///
  /// In en, this message translates to:
  /// **'Upload previous squad works'**
  String get uploadPreviousSquadWorks;

  /// No description provided for @invitePartners.
  ///
  /// In en, this message translates to:
  /// **'Invite Partners'**
  String get invitePartners;

  /// No description provided for @inviteYourPartnersToJoinThe.
  ///
  /// In en, this message translates to:
  /// **'Invite your partners to join the squad'**
  String get inviteYourPartnersToJoinThe;

  /// No description provided for @leader.
  ///
  /// In en, this message translates to:
  /// **'Leader'**
  String get leader;

  /// No description provided for @member.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get member;

  /// No description provided for @makeLeader.
  ///
  /// In en, this message translates to:
  /// **'Make Leader'**
  String get makeLeader;

  /// No description provided for @kickMember.
  ///
  /// In en, this message translates to:
  /// **'Kick Member'**
  String get kickMember;

  /// No description provided for @deleteTheSquadPermanently.
  ///
  /// In en, this message translates to:
  /// **'Delete the squad permanently'**
  String get deleteTheSquadPermanently;

  /// No description provided for @thisIsTheSquadDashboardOnly.
  ///
  /// In en, this message translates to:
  /// **'This is the squad dashboard. Only the leader can edit details, manage members, and add portfolio works.'**
  String get thisIsTheSquadDashboardOnly;

  /// No description provided for @addToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Add to Favorites'**
  String get addToFavorites;

  /// No description provided for @squadInfo.
  ///
  /// In en, this message translates to:
  /// **'Squad Info'**
  String get squadInfo;

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get members;

  /// No description provided for @aboutSquad.
  ///
  /// In en, this message translates to:
  /// **'About Squad'**
  String get aboutSquad;

  /// No description provided for @servicesSkills.
  ///
  /// In en, this message translates to:
  /// **'Services & Skills'**
  String get servicesSkills;

  /// No description provided for @noSkillsDefinedYet.
  ///
  /// In en, this message translates to:
  /// **'No skills defined yet'**
  String get noSkillsDefinedYet;

  /// No description provided for @teamMembers.
  ///
  /// In en, this message translates to:
  /// **'Team Members'**
  String get teamMembers;

  /// No description provided for @memberRemovedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Member removed successfully'**
  String get memberRemovedSuccessfully;

  /// No description provided for @hireSquad.
  ///
  /// In en, this message translates to:
  /// **'Hire Squad'**
  String get hireSquad;

  /// No description provided for @youAreTheLeaderOfThis.
  ///
  /// In en, this message translates to:
  /// **'You are the leader of this squad'**
  String get youAreTheLeaderOfThis;

  /// No description provided for @noPortfolioProjectsYet.
  ///
  /// In en, this message translates to:
  /// **'No portfolio projects yet'**
  String get noPortfolioProjectsYet;

  /// No description provided for @errorLoadingPortfolio.
  ///
  /// In en, this message translates to:
  /// **'Error loading portfolio.'**
  String get errorLoadingPortfolio;

  /// No description provided for @manageMembers.
  ///
  /// In en, this message translates to:
  /// **'Manage Members'**
  String get manageMembers;

  /// No description provided for @noMembersInTheSquad.
  ///
  /// In en, this message translates to:
  /// **'No members in the squad'**
  String get noMembersInTheSquad;

  /// No description provided for @noMembersFound.
  ///
  /// In en, this message translates to:
  /// **'No members found'**
  String get noMembersFound;

  /// No description provided for @kick.
  ///
  /// In en, this message translates to:
  /// **'Kick'**
  String get kick;

  /// No description provided for @memberKickedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Member kicked successfully'**
  String get memberKickedSuccessfully;

  /// No description provided for @promoteToLeader.
  ///
  /// In en, this message translates to:
  /// **'Promote to Leader'**
  String get promoteToLeader;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @leadershipTransferred.
  ///
  /// In en, this message translates to:
  /// **'Leadership transferred'**
  String get leadershipTransferred;

  /// No description provided for @setAsLeader.
  ///
  /// In en, this message translates to:
  /// **'Set as Leader'**
  String get setAsLeader;

  /// No description provided for @pleaseEnterAProductName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a product name'**
  String get pleaseEnterAProductName;

  /// No description provided for @pleaseAddAProductImage.
  ///
  /// In en, this message translates to:
  /// **'Please add a product image'**
  String get pleaseAddAProductImage;

  /// No description provided for @productPublishedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Product published successfully ✅'**
  String get productPublishedSuccessfully;

  /// No description provided for @productImages.
  ///
  /// In en, this message translates to:
  /// **'Product Images *'**
  String get productImages;

  /// No description provided for @productName.
  ///
  /// In en, this message translates to:
  /// **'Product Name *'**
  String get productName;

  /// No description provided for @egNikeSportsShoe.
  ///
  /// In en, this message translates to:
  /// **'e.g. Nike Sports Shoe'**
  String get egNikeSportsShoe;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @writeADetailedDescription.
  ///
  /// In en, this message translates to:
  /// **'Write a detailed description...'**
  String get writeADetailedDescription;

  /// No description provided for @priceSdg.
  ///
  /// In en, this message translates to:
  /// **'Price (SDG)'**
  String get priceSdg;

  /// No description provided for @str000.
  ///
  /// In en, this message translates to:
  /// **'0.00'**
  String get str000;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @eg10.
  ///
  /// In en, this message translates to:
  /// **'e.g. 10'**
  String get eg10;

  /// No description provided for @productCondition.
  ///
  /// In en, this message translates to:
  /// **'Product Condition'**
  String get productCondition;

  /// No description provided for @used.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get used;

  /// No description provided for @targetAgeGroup.
  ///
  /// In en, this message translates to:
  /// **'Target Age Group'**
  String get targetAgeGroup;

  /// No description provided for @baby.
  ///
  /// In en, this message translates to:
  /// **'👶 Baby'**
  String get baby;

  /// No description provided for @child.
  ///
  /// In en, this message translates to:
  /// **'🧒 Child'**
  String get child;

  /// No description provided for @youth.
  ///
  /// In en, this message translates to:
  /// **'👦 Youth'**
  String get youth;

  /// No description provided for @adult.
  ///
  /// In en, this message translates to:
  /// **'👨 Adult'**
  String get adult;

  /// No description provided for @elderly.
  ///
  /// In en, this message translates to:
  /// **'👴 Elderly'**
  String get elderly;

  /// No description provided for @all1.
  ///
  /// In en, this message translates to:
  /// **'👨‍👩‍👧 All'**
  String get all1;

  /// No description provided for @availableSizes.
  ///
  /// In en, this message translates to:
  /// **'Available Sizes'**
  String get availableSizes;

  /// No description provided for @selectFromListOrAddCustom.
  ///
  /// In en, this message translates to:
  /// **'Select from list or add custom size'**
  String get selectFromListOrAddCustom;

  /// No description provided for @customSize.
  ///
  /// In en, this message translates to:
  /// **'Custom size...'**
  String get customSize;

  /// No description provided for @availableColorsVariants.
  ///
  /// In en, this message translates to:
  /// **'Available Colors / Variants'**
  String get availableColorsVariants;

  /// No description provided for @customColorvariant.
  ///
  /// In en, this message translates to:
  /// **'Custom color/variant...'**
  String get customColorvariant;

  /// No description provided for @shippingAvailable.
  ///
  /// In en, this message translates to:
  /// **'🚚 Ships'**
  String get shippingAvailable;

  /// No description provided for @enableIfYouOfferDeliveryService.
  ///
  /// In en, this message translates to:
  /// **'Enable if you offer delivery service'**
  String get enableIfYouOfferDeliveryService;

  /// No description provided for @relationshipRequestCancelled.
  ///
  /// In en, this message translates to:
  /// **'Relationship / Request cancelled'**
  String get relationshipRequestCancelled;

  /// No description provided for @partnerRequestSentSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Partner request sent successfully!'**
  String get partnerRequestSentSuccessfully;

  /// No description provided for @locationNotAvailableForThisUser.
  ///
  /// In en, this message translates to:
  /// **'Location not available for this user'**
  String get locationNotAvailableForThisUser;

  /// No description provided for @contactMe.
  ///
  /// In en, this message translates to:
  /// **'Contact Me'**
  String get contactMe;

  /// No description provided for @errorCreatingChat.
  ///
  /// In en, this message translates to:
  /// **'Error creating chat'**
  String get errorCreatingChat;

  /// No description provided for @ongoing.
  ///
  /// In en, this message translates to:
  /// **'Ongoing'**
  String get ongoing;

  /// No description provided for @viewProjectDetails.
  ///
  /// In en, this message translates to:
  /// **'View Project Details'**
  String get viewProjectDetails;

  /// No description provided for @personal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get personal;

  /// No description provided for @startup.
  ///
  /// In en, this message translates to:
  /// **'Startup'**
  String get startup;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @vouchersList.
  ///
  /// In en, this message translates to:
  /// **'Vouchers List'**
  String get vouchersList;

  /// No description provided for @masterDashboard.
  ///
  /// In en, this message translates to:
  /// **'Master Dashboard'**
  String get masterDashboard;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @youHaveNoApprenticesCurrently.
  ///
  /// In en, this message translates to:
  /// **'You have no apprentices currently'**
  String get youHaveNoApprenticesCurrently;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'Error occurred'**
  String get errorOccurred;

  /// No description provided for @craftsman.
  ///
  /// In en, this message translates to:
  /// **'Craftsman'**
  String get craftsman;

  /// No description provided for @assignTask.
  ///
  /// In en, this message translates to:
  /// **'Assign Task'**
  String get assignTask;

  /// No description provided for @fireApprentice.
  ///
  /// In en, this message translates to:
  /// **'Fire Apprentice'**
  String get fireApprentice;

  /// No description provided for @fire.
  ///
  /// In en, this message translates to:
  /// **'Fire'**
  String get fire;

  /// No description provided for @noPendingRequestsCurrently.
  ///
  /// In en, this message translates to:
  /// **'No pending requests currently'**
  String get noPendingRequestsCurrently;

  /// No description provided for @wantsToJoinAsYourApprentice.
  ///
  /// In en, this message translates to:
  /// **'Wants to join as your apprentice'**
  String get wantsToJoinAsYourApprentice;

  /// No description provided for @assignRequest.
  ///
  /// In en, this message translates to:
  /// **'Assign Request'**
  String get assignRequest;

  /// No description provided for @noActiveRequestsAvailableToAssign.
  ///
  /// In en, this message translates to:
  /// **'No active requests available to assign'**
  String get noActiveRequestsAvailableToAssign;

  /// No description provided for @requestAssignedSuccessfullyClientWillBe.
  ///
  /// In en, this message translates to:
  /// **'Request assigned successfully! Client will be notified.'**
  String get requestAssignedSuccessfullyClientWillBe;

  /// No description provided for @errorAssigningTask.
  ///
  /// In en, this message translates to:
  /// **'Error assigning task'**
  String get errorAssigningTask;

  /// No description provided for @assign.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get assign;

  /// No description provided for @digitalIdCard.
  ///
  /// In en, this message translates to:
  /// **'Digital ID Card'**
  String get digitalIdCard;

  /// No description provided for @shareCard.
  ///
  /// In en, this message translates to:
  /// **'Share Card'**
  String get shareCard;

  /// No description provided for @digitalId.
  ///
  /// In en, this message translates to:
  /// **'DIGITAL ID'**
  String get digitalId;

  /// No description provided for @coreSkills.
  ///
  /// In en, this message translates to:
  /// **'Core Skills'**
  String get coreSkills;

  /// No description provided for @scanToConnectWithMe.
  ///
  /// In en, this message translates to:
  /// **'Scan to connect with me'**
  String get scanToConnectWithMe;

  /// No description provided for @ifYouDoNotHaveThe.
  ///
  /// In en, this message translates to:
  /// **'If you do not have the app, you will be redirected to download it!'**
  String get ifYouDoNotHaveThe;

  /// No description provided for @tapToReturnToId.
  ///
  /// In en, this message translates to:
  /// **'Tap to return to ID'**
  String get tapToReturnToId;

  /// No description provided for @noDescription.
  ///
  /// In en, this message translates to:
  /// **'No description'**
  String get noDescription;

  /// No description provided for @hiddenFromStoreFavorites.
  ///
  /// In en, this message translates to:
  /// **'Hidden from store & favorites'**
  String get hiddenFromStoreFavorites;

  /// No description provided for @show1.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get show1;

  /// No description provided for @strHide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get strHide;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteProduct.
  ///
  /// In en, this message translates to:
  /// **'Delete Product'**
  String get deleteProduct;

  /// No description provided for @areYouSure.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get areYouSure;

  /// No description provided for @manageShopGallery.
  ///
  /// In en, this message translates to:
  /// **'Manage Shop Gallery'**
  String get manageShopGallery;

  /// No description provided for @galleryIsEmptyAddSomeImages.
  ///
  /// In en, this message translates to:
  /// **'Gallery is empty. Add some images.'**
  String get galleryIsEmptyAddSomeImages;

  /// No description provided for @addImage.
  ///
  /// In en, this message translates to:
  /// **'Add Image'**
  String get addImage;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @partners.
  ///
  /// In en, this message translates to:
  /// **'Partners'**
  String get partners;

  /// No description provided for @savedAccounts.
  ///
  /// In en, this message translates to:
  /// **'Saved Accounts'**
  String get savedAccounts;

  /// No description provided for @savedPosts.
  ///
  /// In en, this message translates to:
  /// **'Saved Posts'**
  String get savedPosts;

  /// No description provided for @removePartner.
  ///
  /// In en, this message translates to:
  /// **'Remove Partner'**
  String get removePartner;

  /// No description provided for @recommendationSentSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Recommendation sent successfully!'**
  String get recommendationSentSuccessfully;

  /// No description provided for @errorSendingRecommendationYouMayHave.
  ///
  /// In en, this message translates to:
  /// **'Error sending recommendation, you may have already vouched.'**
  String get errorSendingRecommendationYouMayHave;

  /// No description provided for @apprenticeshipRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Apprenticeship request sent!'**
  String get apprenticeshipRequestSent;

  /// No description provided for @errorSendingRequest.
  ///
  /// In en, this message translates to:
  /// **'Error sending request'**
  String get errorSendingRequest;

  /// No description provided for @cancelApprenticeship.
  ///
  /// In en, this message translates to:
  /// **'Cancel Apprenticeship'**
  String get cancelApprenticeship;

  /// No description provided for @areYouSureYouWantTo3.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel? If you are the apprentice, a request will be sent for approval.'**
  String get areYouSureYouWantTo3;

  /// No description provided for @apprenticeshipCanceled.
  ///
  /// In en, this message translates to:
  /// **'Apprenticeship canceled'**
  String get apprenticeshipCanceled;

  /// No description provided for @leaveRequestSentToMaster.
  ///
  /// In en, this message translates to:
  /// **'Leave request sent to master'**
  String get leaveRequestSentToMaster;

  /// No description provided for @addAccountsFromTheirProfiles.
  ///
  /// In en, this message translates to:
  /// **'Add accounts from their profiles'**
  String get addAccountsFromTheirProfiles;

  /// No description provided for @sudanfreeAccount.
  ///
  /// In en, this message translates to:
  /// **'SudanFree Account'**
  String get sudanfreeAccount;

  /// No description provided for @vouch.
  ///
  /// In en, this message translates to:
  /// **'Vouch'**
  String get vouch;

  /// No description provided for @requestApprenticeship.
  ///
  /// In en, this message translates to:
  /// **'Request Apprenticeship'**
  String get requestApprenticeship;

  /// No description provided for @noFavoriteSquadsYet.
  ///
  /// In en, this message translates to:
  /// **'No favorite squads yet'**
  String get noFavoriteSquadsYet;

  /// No description provided for @noSavedPostsOrProducts.
  ///
  /// In en, this message translates to:
  /// **'No saved posts or products'**
  String get noSavedPostsOrProducts;

  /// No description provided for @sdg.
  ///
  /// In en, this message translates to:
  /// **'SDG'**
  String get sdg;

  /// No description provided for @notSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get notSpecified;

  /// No description provided for @projectDetails.
  ///
  /// In en, this message translates to:
  /// **'Project Details'**
  String get projectDetails;

  /// No description provided for @editProject.
  ///
  /// In en, this message translates to:
  /// **'Edit Project'**
  String get editProject;

  /// No description provided for @projectExecutors.
  ///
  /// In en, this message translates to:
  /// **'Project Executors'**
  String get projectExecutors;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @projectPurpose.
  ///
  /// In en, this message translates to:
  /// **'Project Purpose'**
  String get projectPurpose;

  /// No description provided for @visitProjectLink.
  ///
  /// In en, this message translates to:
  /// **'Visit Project Link'**
  String get visitProjectLink;

  /// No description provided for @openOnMap.
  ///
  /// In en, this message translates to:
  /// **'Open on Map'**
  String get openOnMap;

  /// No description provided for @myFavorites.
  ///
  /// In en, this message translates to:
  /// **'My Favorites'**
  String get myFavorites;

  /// No description provided for @editProfileUpgradeAccount.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile / Upgrade Account'**
  String get editProfileUpgradeAccount;

  /// No description provided for @pleaseFillBothFieldsWhatYou.
  ///
  /// In en, this message translates to:
  /// **'Please fill both fields: what you offer and what you need'**
  String get pleaseFillBothFieldsWhatYou;

  /// No description provided for @pleaseAddPromotionalImagesForThe.
  ///
  /// In en, this message translates to:
  /// **'Please add promotional images for the product, as text-only posts do not display details well'**
  String get pleaseAddPromotionalImagesForThe;

  /// No description provided for @pleaseWriteTextAddImageOr.
  ///
  /// In en, this message translates to:
  /// **'Please write text, add image, or add a poll'**
  String get pleaseWriteTextAddImageOr;

  /// No description provided for @pleaseClassifyYourPostGeneralDiscussion.
  ///
  /// In en, this message translates to:
  /// **'Please classify your post (General, Discussion, Buy/Sell, Help, Announcement, or Question)'**
  String get pleaseClassifyYourPostGeneralDiscussion;

  /// No description provided for @postUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Post updated successfully ✅'**
  String get postUpdatedSuccessfully;

  /// No description provided for @postingInBackground.
  ///
  /// In en, this message translates to:
  /// **'Posting in background... ⏳'**
  String get postingInBackground;

  /// No description provided for @anErrorOccurredPleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'An error occurred, please try again'**
  String get anErrorOccurredPleaseTryAgain;

  /// No description provided for @searchPosts.
  ///
  /// In en, this message translates to:
  /// **'Search posts...'**
  String get searchPosts;

  /// No description provided for @noCommentsYet.
  ///
  /// In en, this message translates to:
  /// **'No comments yet'**
  String get noCommentsYet;

  /// No description provided for @beTheFirstToComment.
  ///
  /// In en, this message translates to:
  /// **'Be the first to comment! 💬'**
  String get beTheFirstToComment;

  /// No description provided for @writeACommentToMention.
  ///
  /// In en, this message translates to:
  /// **'Write a comment... (use @ to mention)'**
  String get writeACommentToMention;

  /// No description provided for @writeAReply.
  ///
  /// In en, this message translates to:
  /// **'Write a reply...'**
  String get writeAReply;

  /// No description provided for @plumber.
  ///
  /// In en, this message translates to:
  /// **'Plumber'**
  String get plumber;

  /// No description provided for @electrician.
  ///
  /// In en, this message translates to:
  /// **'Electrician'**
  String get electrician;

  /// No description provided for @carpenter.
  ///
  /// In en, this message translates to:
  /// **'Carpenter'**
  String get carpenter;

  /// No description provided for @painter.
  ///
  /// In en, this message translates to:
  /// **'Painter'**
  String get painter;

  /// No description provided for @mechanic.
  ///
  /// In en, this message translates to:
  /// **'Mechanic'**
  String get mechanic;

  /// No description provided for @designer.
  ///
  /// In en, this message translates to:
  /// **'Designer'**
  String get designer;

  /// No description provided for @developer.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get developer;

  /// No description provided for @restaurant.
  ///
  /// In en, this message translates to:
  /// **'Restaurant'**
  String get restaurant;

  /// No description provided for @pharmacy.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy'**
  String get pharmacy;

  /// No description provided for @clothing.
  ///
  /// In en, this message translates to:
  /// **'Clothing'**
  String get clothing;

  /// No description provided for @findTheBestProfessionalsServices.
  ///
  /// In en, this message translates to:
  /// **'Find the best professionals & services'**
  String get findTheBestProfessionalsServices;

  /// No description provided for @quickSearch.
  ///
  /// In en, this message translates to:
  /// **'🔥 Quick Search'**
  String get quickSearch;

  /// No description provided for @searchTips.
  ///
  /// In en, this message translates to:
  /// **'Search Tips'**
  String get searchTips;

  /// No description provided for @searchByNameProfessionOrLocationn.
  ///
  /// In en, this message translates to:
  /// **'• Search by name, profession, or location\\n• Try \"plumber in Omdurman\" for combined search\\n• You can type a neighborhood or state name'**
  String get searchByNameProfessionOrLocationn;

  /// No description provided for @min.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get min;

  /// No description provided for @avg.
  ///
  /// In en, this message translates to:
  /// **'Avg'**
  String get avg;

  /// No description provided for @max.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get max;

  /// No description provided for @perHour.
  ///
  /// In en, this message translates to:
  /// **'per hour'**
  String get perHour;

  /// No description provided for @pressSearchForFullResults.
  ///
  /// In en, this message translates to:
  /// **'Press search for full results'**
  String get pressSearchForFullResults;

  /// No description provided for @chats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chats;

  /// No description provided for @noPreviousChats.
  ///
  /// In en, this message translates to:
  /// **'No previous chats'**
  String get noPreviousChats;

  /// No description provided for @contactFreelancersOrShopsToAgree.
  ///
  /// In en, this message translates to:
  /// **'Contact freelancers or shops to agree on services.'**
  String get contactFreelancersOrShopsToAgree;

  /// No description provided for @searchNow.
  ///
  /// In en, this message translates to:
  /// **'Search Now'**
  String get searchNow;

  /// No description provided for @chatStarted.
  ///
  /// In en, this message translates to:
  /// **'Chat started'**
  String get chatStarted;

  /// No description provided for @submittedOffers.
  ///
  /// In en, this message translates to:
  /// **'Submitted Offers'**
  String get submittedOffers;

  /// No description provided for @noOffersSubmittedYet.
  ///
  /// In en, this message translates to:
  /// **'No offers submitted yet'**
  String get noOffersSubmittedYet;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @proposedBudget.
  ///
  /// In en, this message translates to:
  /// **'Proposed Budget'**
  String get proposedBudget;

  /// No description provided for @estimatedTime.
  ///
  /// In en, this message translates to:
  /// **'Estimated Time'**
  String get estimatedTime;

  /// No description provided for @offerDetails.
  ///
  /// In en, this message translates to:
  /// **'Offer Details:'**
  String get offerDetails;

  /// No description provided for @contactProvider.
  ///
  /// In en, this message translates to:
  /// **'Contact Provider'**
  String get contactProvider;

  /// No description provided for @directCall.
  ///
  /// In en, this message translates to:
  /// **'Direct Call'**
  String get directCall;

  /// No description provided for @acceptAgreeCreateAgreement.
  ///
  /// In en, this message translates to:
  /// **'Accept & Agree (Create Agreement)'**
  String get acceptAgreeCreateAgreement;

  /// No description provided for @helloIAmContactingYouRegarding.
  ///
  /// In en, this message translates to:
  /// **'Hello, I am contacting you regarding the offer you submitted on my request in Sudan Free platform.'**
  String get helloIAmContactingYouRegarding;

  /// No description provided for @marketplace.
  ///
  /// In en, this message translates to:
  /// **'Marketplace'**
  String get marketplace;

  /// No description provided for @noActiveOffersRightNow.
  ///
  /// In en, this message translates to:
  /// **'No active offers right now'**
  String get noActiveOffersRightNow;

  /// No description provided for @beTheFirstToPostAn.
  ///
  /// In en, this message translates to:
  /// **'Be the first to post an offer!'**
  String get beTheFirstToPostAn;

  /// No description provided for @postOffer.
  ///
  /// In en, this message translates to:
  /// **'Post Offer +'**
  String get postOffer;

  /// No description provided for @searchOffers.
  ///
  /// In en, this message translates to:
  /// **'Search offers...'**
  String get searchOffers;

  /// No description provided for @deleteOffer.
  ///
  /// In en, this message translates to:
  /// **'Delete Offer'**
  String get deleteOffer;

  /// No description provided for @areYouSureYouWantTo4.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this offer permanently?'**
  String get areYouSureYouWantTo4;

  /// No description provided for @deletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Deleted successfully'**
  String get deletedSuccessfully;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @pleaseWriteRequestDetails.
  ///
  /// In en, this message translates to:
  /// **'Please write request details'**
  String get pleaseWriteRequestDetails;

  /// No description provided for @pleaseSelectTheWorkType.
  ///
  /// In en, this message translates to:
  /// **'Please select the work type'**
  String get pleaseSelectTheWorkType;

  /// No description provided for @preparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing...'**
  String get preparing;

  /// No description provided for @uploadingAudio.
  ///
  /// In en, this message translates to:
  /// **'Uploading audio...'**
  String get uploadingAudio;

  /// No description provided for @publishingRequest.
  ///
  /// In en, this message translates to:
  /// **'Publishing request...'**
  String get publishingRequest;

  /// No description provided for @yourRequestHasBeenPublishedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Your request has been published successfully!'**
  String get yourRequestHasBeenPublishedSuccessfully;

  /// No description provided for @cars.
  ///
  /// In en, this message translates to:
  /// **'Cars'**
  String get cars;

  /// No description provided for @realEstate.
  ///
  /// In en, this message translates to:
  /// **'Real Estate'**
  String get realEstate;

  /// No description provided for @electronics.
  ///
  /// In en, this message translates to:
  /// **'Electronics'**
  String get electronics;

  /// No description provided for @clothes.
  ///
  /// In en, this message translates to:
  /// **'Clothes'**
  String get clothes;

  /// No description provided for @food.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get food;

  /// No description provided for @construction.
  ///
  /// In en, this message translates to:
  /// **'Construction'**
  String get construction;

  /// No description provided for @addNewRequest.
  ///
  /// In en, this message translates to:
  /// **'Add New Request'**
  String get addNewRequest;

  /// No description provided for @describeYourRequestClearlyAndAttach.
  ///
  /// In en, this message translates to:
  /// **'Describe your request clearly and attach images if possible for better offers.'**
  String get describeYourRequestClearlyAndAttach;

  /// No description provided for @noticeAllRequestsAreTemporaryOffers.
  ///
  /// In en, this message translates to:
  /// **'Notice: All requests are \"Temporary Offers\" and will be automatically deleted after 48 hours.'**
  String get noticeAllRequestsAreTemporaryOffers;

  /// No description provided for @workType.
  ///
  /// In en, this message translates to:
  /// **'Work Type *'**
  String get workType;

  /// No description provided for @requestDetails.
  ///
  /// In en, this message translates to:
  /// **'Request Details *'**
  String get requestDetails;

  /// No description provided for @exampleINeedAPlumberTo.
  ///
  /// In en, this message translates to:
  /// **'Example: I need a plumber to fix a bathroom leak, urgent work preferred today...'**
  String get exampleINeedAPlumberTo;

  /// No description provided for @attachedImagesOptional.
  ///
  /// In en, this message translates to:
  /// **'Attached Images (optional)'**
  String get attachedImagesOptional;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get addPhoto;

  /// No description provided for @voiceRecordOptional.
  ///
  /// In en, this message translates to:
  /// **'Voice Record (optional)'**
  String get voiceRecordOptional;

  /// No description provided for @youCanRecordAVoiceExplanation.
  ///
  /// In en, this message translates to:
  /// **'You can record a voice explanation for your request'**
  String get youCanRecordAVoiceExplanation;

  /// No description provided for @tapToStartRecording.
  ///
  /// In en, this message translates to:
  /// **'Tap to start recording'**
  String get tapToStartRecording;

  /// No description provided for @workLocationOptional.
  ///
  /// In en, this message translates to:
  /// **'Work Location (optional)'**
  String get workLocationOptional;

  /// No description provided for @specifyLocationIfTheWorkRequires.
  ///
  /// In en, this message translates to:
  /// **'Specify location if the work requires attendance'**
  String get specifyLocationIfTheWorkRequires;

  /// No description provided for @localityCity.
  ///
  /// In en, this message translates to:
  /// **'Locality / City'**
  String get localityCity;

  /// No description provided for @postRequest.
  ///
  /// In en, this message translates to:
  /// **'Post Request'**
  String get postRequest;

  /// No description provided for @submitYourOffer.
  ///
  /// In en, this message translates to:
  /// **'Submit your offer'**
  String get submitYourOffer;

  /// No description provided for @helloIAmReadyToFulfill.
  ///
  /// In en, this message translates to:
  /// **'Hello, I am ready to fulfill your request. I have previous experience...'**
  String get helloIAmReadyToFulfill;

  /// No description provided for @estimatedPriceOptional.
  ///
  /// In en, this message translates to:
  /// **'Estimated Price (Optional)'**
  String get estimatedPriceOptional;

  /// No description provided for @estimatedTimeToCompleteOptional.
  ///
  /// In en, this message translates to:
  /// **'Estimated time to complete (Optional)'**
  String get estimatedTimeToCompleteOptional;

  /// No description provided for @pleaseWriteOfferDetails.
  ///
  /// In en, this message translates to:
  /// **'Please write offer details'**
  String get pleaseWriteOfferDetails;

  /// No description provided for @youHaveReachedTheMaximumOffers.
  ///
  /// In en, this message translates to:
  /// **'You have reached the maximum offers (2)'**
  String get youHaveReachedTheMaximumOffers;

  /// No description provided for @newOffer.
  ///
  /// In en, this message translates to:
  /// **'New Offer'**
  String get newOffer;

  /// No description provided for @offerSubmittedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Offer submitted successfully!'**
  String get offerSubmittedSuccessfully;

  /// No description provided for @submitOffer.
  ///
  /// In en, this message translates to:
  /// **'Submit Offer'**
  String get submitOffer;

  /// No description provided for @requestDetails1.
  ///
  /// In en, this message translates to:
  /// **'Request Details'**
  String get requestDetails1;

  /// No description provided for @applyLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Apply limit reached'**
  String get applyLimitReached;

  /// No description provided for @viewOffers.
  ///
  /// In en, this message translates to:
  /// **'View Offers'**
  String get viewOffers;

  /// No description provided for @pleaseDeleteTheRequestFromThe.
  ///
  /// In en, this message translates to:
  /// **'Please delete the request from the trash icon above when you are satisfied and received the service.'**
  String get pleaseDeleteTheRequestFromThe;

  /// No description provided for @youHaveReachedTheMaximumOffers1.
  ///
  /// In en, this message translates to:
  /// **'You have reached the maximum offers (2) on this request'**
  String get youHaveReachedTheMaximumOffers1;

  /// No description provided for @thisIsYourLastOfferOn.
  ///
  /// In en, this message translates to:
  /// **'This is your last offer on this request'**
  String get thisIsYourLastOfferOn;

  /// No description provided for @deleteRequest.
  ///
  /// In en, this message translates to:
  /// **'Delete Request'**
  String get deleteRequest;

  /// No description provided for @areYouSureYouWantTo5.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this request? This cannot be undone.'**
  String get areYouSureYouWantTo5;

  /// No description provided for @deletedSuccessfully1.
  ///
  /// In en, this message translates to:
  /// **'Deleted Successfully'**
  String get deletedSuccessfully1;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @inGeneral.
  ///
  /// In en, this message translates to:
  /// **'in general'**
  String get inGeneral;

  /// No description provided for @searchFreelancer.
  ///
  /// In en, this message translates to:
  /// **'Search freelancer...'**
  String get searchFreelancer;

  /// No description provided for @readAll.
  ///
  /// In en, this message translates to:
  /// **'Read all'**
  String get readAll;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// No description provided for @stayUpdatedBrowseTheCommunityNow.
  ///
  /// In en, this message translates to:
  /// **'Stay updated! Browse the community now.'**
  String get stayUpdatedBrowseTheCommunityNow;

  /// No description provided for @exploreCommunity.
  ///
  /// In en, this message translates to:
  /// **'Explore Community'**
  String get exploreCommunity;

  /// No description provided for @newReaction.
  ///
  /// In en, this message translates to:
  /// **'New Reaction'**
  String get newReaction;

  /// No description provided for @newComment.
  ///
  /// In en, this message translates to:
  /// **'New Comment'**
  String get newComment;

  /// No description provided for @youWereMentioned.
  ///
  /// In en, this message translates to:
  /// **'You were mentioned'**
  String get youWereMentioned;

  /// No description provided for @newRating.
  ///
  /// In en, this message translates to:
  /// **'New Rating'**
  String get newRating;

  /// No description provided for @partnerRequest.
  ///
  /// In en, this message translates to:
  /// **'Partner Request'**
  String get partnerRequest;

  /// No description provided for @newMessage.
  ///
  /// In en, this message translates to:
  /// **'New Message'**
  String get newMessage;

  /// No description provided for @newFollower.
  ///
  /// In en, this message translates to:
  /// **'New Follower'**
  String get newFollower;

  /// No description provided for @warning1.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning1;

  /// No description provided for @rateYourExperience.
  ///
  /// In en, this message translates to:
  /// **'Rate your experience'**
  String get rateYourExperience;

  /// No description provided for @newAssignment.
  ///
  /// In en, this message translates to:
  /// **'New Assignment'**
  String get newAssignment;

  /// No description provided for @now.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get now;

  /// No description provided for @sorryTheAdHasExpiredOr.
  ///
  /// In en, this message translates to:
  /// **'Sorry, the ad has expired or been deleted'**
  String get sorryTheAdHasExpiredOr;

  /// No description provided for @deleteNotification.
  ///
  /// In en, this message translates to:
  /// **'Delete Notification'**
  String get deleteNotification;

  /// No description provided for @areYouSureYouWantTo6.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this notification?'**
  String get areYouSureYouWantTo6;

  /// No description provided for @joinedSquadSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Joined squad successfully ✅'**
  String get joinedSquadSuccessfully;

  /// No description provided for @squadInviteDeclined.
  ///
  /// In en, this message translates to:
  /// **'Squad invite declined ❌'**
  String get squadInviteDeclined;

  /// No description provided for @partnerRequestAccepted.
  ///
  /// In en, this message translates to:
  /// **'Partner request accepted ✅'**
  String get partnerRequestAccepted;

  /// No description provided for @partnerRequestDeclined.
  ///
  /// In en, this message translates to:
  /// **'Partner request declined ❌'**
  String get partnerRequestDeclined;

  /// No description provided for @mentionAColleague.
  ///
  /// In en, this message translates to:
  /// **'Mention a colleague'**
  String get mentionAColleague;

  /// No description provided for @everyone.
  ///
  /// In en, this message translates to:
  /// **'@Everyone'**
  String get everyone;

  /// No description provided for @noColleaguesYet.
  ///
  /// In en, this message translates to:
  /// **'No colleagues yet'**
  String get noColleaguesYet;

  /// No description provided for @addColleaguesFromTheirProfilesTo.
  ///
  /// In en, this message translates to:
  /// **'Add colleagues from their profiles to mention them'**
  String get addColleaguesFromTheirProfilesTo;

  /// No description provided for @premiumVerifiedRoyalAccount.
  ///
  /// In en, this message translates to:
  /// **'👑 Premium — Verified Royal Account'**
  String get premiumVerifiedRoyalAccount;

  /// No description provided for @topProVerifiedWithExcellentRatings.
  ///
  /// In en, this message translates to:
  /// **'⭐ Top Pro — Verified with excellent ratings'**
  String get topProVerifiedWithExcellentRatings;

  /// No description provided for @identityVerified.
  ///
  /// In en, this message translates to:
  /// **'✅ Identity Verified'**
  String get identityVerified;

  /// No description provided for @phoneVerified.
  ///
  /// In en, this message translates to:
  /// **'📱 Phone Verified'**
  String get phoneVerified;

  /// No description provided for @exceptional.
  ///
  /// In en, this message translates to:
  /// **'Exceptional'**
  String get exceptional;

  /// No description provided for @excellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get excellent;

  /// No description provided for @veryGood.
  ///
  /// In en, this message translates to:
  /// **'Very Good'**
  String get veryGood;

  /// No description provided for @good.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get good;

  /// No description provided for @starter.
  ///
  /// In en, this message translates to:
  /// **'Starter'**
  String get starter;

  /// No description provided for @copyComment.
  ///
  /// In en, this message translates to:
  /// **'Copy comment'**
  String get copyComment;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @deleteComment.
  ///
  /// In en, this message translates to:
  /// **'Delete comment'**
  String get deleteComment;

  /// No description provided for @writeACommentOptional.
  ///
  /// In en, this message translates to:
  /// **'Write a comment (optional)'**
  String get writeACommentOptional;

  /// No description provided for @wasThePurchaseCompletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Was the purchase completed successfully?'**
  String get wasThePurchaseCompletedSuccessfully;

  /// No description provided for @didTheFreelancerCompleteTheWork.
  ///
  /// In en, this message translates to:
  /// **'Did the freelancer complete the work?'**
  String get didTheFreelancerCompleteTheWork;

  /// No description provided for @wouldYouRecommendThem.
  ///
  /// In en, this message translates to:
  /// **'Would you recommend them?'**
  String get wouldYouRecommendThem;

  /// No description provided for @wouldYouWorkWithThemAgain.
  ///
  /// In en, this message translates to:
  /// **'Would you work with them again?'**
  String get wouldYouWorkWithThemAgain;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @tapToRate.
  ///
  /// In en, this message translates to:
  /// **'Tap to rate'**
  String get tapToRate;

  /// No description provided for @poor.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get poor;

  /// No description provided for @fair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get fair;

  /// No description provided for @project.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get project;

  /// No description provided for @wouldWorkAgain.
  ///
  /// In en, this message translates to:
  /// **'Would work again'**
  String get wouldWorkAgain;

  /// No description provided for @wouldNotRecommend.
  ///
  /// In en, this message translates to:
  /// **'Would not recommend'**
  String get wouldNotRecommend;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @pinned.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get pinned;

  /// No description provided for @sharedAPostOnSudanfree.
  ///
  /// In en, this message translates to:
  /// **'shared a post on SudanFree'**
  String get sharedAPostOnSudanfree;

  /// No description provided for @downloadAppToViewPost.
  ///
  /// In en, this message translates to:
  /// **'Download app to view post'**
  String get downloadAppToViewPost;

  /// No description provided for @postFromSudanfree.
  ///
  /// In en, this message translates to:
  /// **'Post from SudanFree'**
  String get postFromSudanfree;

  /// No description provided for @removeFromPortfolio.
  ///
  /// In en, this message translates to:
  /// **'Remove from Portfolio'**
  String get removeFromPortfolio;

  /// No description provided for @addToPortfolio.
  ///
  /// In en, this message translates to:
  /// **'Add to Portfolio'**
  String get addToPortfolio;

  /// No description provided for @updatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Updated successfully'**
  String get updatedSuccessfully;

  /// No description provided for @updateFailed.
  ///
  /// In en, this message translates to:
  /// **'Update failed'**
  String get updateFailed;

  /// No description provided for @deletionFailed.
  ///
  /// In en, this message translates to:
  /// **'Deletion failed'**
  String get deletionFailed;

  /// No description provided for @seeMore.
  ///
  /// In en, this message translates to:
  /// **'See more...'**
  String get seeMore;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @contactMeViaWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Contact me via WhatsApp, I saw your profile on SudanFree'**
  String get contactMeViaWhatsapp;

  /// No description provided for @typing.
  ///
  /// In en, this message translates to:
  /// **'Typing...'**
  String get typing;

  /// No description provided for @onlineNow.
  ///
  /// In en, this message translates to:
  /// **'Online now'**
  String get onlineNow;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @lastSeen.
  ///
  /// In en, this message translates to:
  /// **'Last seen'**
  String get lastSeen;

  /// No description provided for @image.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get image;

  /// No description provided for @file.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get file;

  /// No description provided for @recordingAudio.
  ///
  /// In en, this message translates to:
  /// **'Recording...'**
  String get recordingAudio;

  /// No description provided for @availableForWork.
  ///
  /// In en, this message translates to:
  /// **'Available for Work'**
  String get availableForWork;

  /// No description provided for @currentlyUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Currently Unavailable'**
  String get currentlyUnavailable;

  /// No description provided for @visibleToAll.
  ///
  /// In en, this message translates to:
  /// **'Visible to all'**
  String get visibleToAll;

  /// No description provided for @hiddenFromMap.
  ///
  /// In en, this message translates to:
  /// **'Hidden from map'**
  String get hiddenFromMap;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @privacyAndSecurity.
  ///
  /// In en, this message translates to:
  /// **'Privacy and Security'**
  String get privacyAndSecurity;

  /// No description provided for @chatWarning.
  ///
  /// In en, this message translates to:
  /// **'It is recommended to use WhatsApp or direct call to communicate. Chat here is only to create agreements to ensure your rights.'**
  String get chatWarning;

  /// No description provided for @createAgreement.
  ///
  /// In en, this message translates to:
  /// **'Create Agreement'**
  String get createAgreement;

  /// No description provided for @fileSizeError.
  ///
  /// In en, this message translates to:
  /// **'File size too large, maximum is 10 MB'**
  String get fileSizeError;

  /// No description provided for @filePickError.
  ///
  /// In en, this message translates to:
  /// **'Error selecting file'**
  String get filePickError;

  /// No description provided for @createAgreementChat.
  ///
  /// In en, this message translates to:
  /// **'Create Agreement (Chat)'**
  String get createAgreementChat;

  /// No description provided for @contactWith.
  ///
  /// In en, this message translates to:
  /// **'Contact {name}'**
  String contactWith(String name);

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// No description provided for @interestsSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} interests selected'**
  String interestsSelected(int count);

  /// No description provided for @productLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Product link copied ✅'**
  String get productLinkCopied;

  /// No description provided for @shopNotFound.
  ///
  /// In en, this message translates to:
  /// **'Shop not found'**
  String get shopNotFound;

  /// No description provided for @orderProductWhatsAppMessage.
  ///
  /// In en, this message translates to:
  /// **'Hello, I want to order this product:\n{productName}\n{productUrl}\n\nIs it available?'**
  String orderProductWhatsAppMessage(String productName, String productUrl);

  /// No description provided for @orderNowVia.
  ///
  /// In en, this message translates to:
  /// **'Order Now via'**
  String get orderNowVia;

  /// No description provided for @whatsappNotFound.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp not found'**
  String get whatsappNotFound;

  /// No description provided for @inAppChat.
  ///
  /// In en, this message translates to:
  /// **'In-App Chat'**
  String get inAppChat;

  /// No description provided for @errorOpeningChat.
  ///
  /// In en, this message translates to:
  /// **'Error opening chat'**
  String get errorOpeningChat;

  /// No description provided for @deleteProductPrompt.
  ///
  /// In en, this message translates to:
  /// **'Delete this product?'**
  String get deleteProductPrompt;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String minutesAgo(int minutes);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String hoursAgo(int hours);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String daysAgo(int days);

  /// No description provided for @detailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get detailsTitle;

  /// No description provided for @replyingTo.
  ///
  /// In en, this message translates to:
  /// **'Replying to {name}'**
  String replyingTo(String name);

  /// No description provided for @writeComment.
  ///
  /// In en, this message translates to:
  /// **'Write a comment...'**
  String get writeComment;

  /// No description provided for @commentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get commentsTitle;

  /// No description provided for @commentPosted.
  ///
  /// In en, this message translates to:
  /// **'Comment posted successfully'**
  String get commentPosted;

  /// No description provided for @errorPostingComment.
  ///
  /// In en, this message translates to:
  /// **'Error posting comment'**
  String get errorPostingComment;

  /// No description provided for @postToCommunity.
  ///
  /// In en, this message translates to:
  /// **'Post to Community'**
  String get postToCommunity;

  /// No description provided for @orderNow.
  ///
  /// In en, this message translates to:
  /// **'Order Now'**
  String get orderNow;

  /// No description provided for @productInfo.
  ///
  /// In en, this message translates to:
  /// **'Product Info'**
  String get productInfo;

  /// No description provided for @ageGroup.
  ///
  /// In en, this message translates to:
  /// **'Age Group'**
  String get ageGroup;

  /// No description provided for @availableQty.
  ///
  /// In en, this message translates to:
  /// **'Available Qty'**
  String get availableQty;

  /// No description provided for @shopProducts.
  ///
  /// In en, this message translates to:
  /// **'Shop Products'**
  String get shopProducts;

  /// No description provided for @saveToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Save to Favorites'**
  String get saveToFavorites;

  /// No description provided for @productType.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get productType;

  /// No description provided for @linkedProduct.
  ///
  /// In en, this message translates to:
  /// **'Linked Product'**
  String get linkedProduct;

  /// No description provided for @buyProduct.
  ///
  /// In en, this message translates to:
  /// **'Buy Product'**
  String get buyProduct;

  /// No description provided for @like.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get like;

  /// No description provided for @comment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get comment;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @replyAction.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get replyAction;

  /// No description provided for @copyText.
  ///
  /// In en, this message translates to:
  /// **'Copy text'**
  String get copyText;

  /// No description provided for @textCopied.
  ///
  /// In en, this message translates to:
  /// **'Text copied'**
  String get textCopied;

  /// No description provided for @showReplies.
  ///
  /// In en, this message translates to:
  /// **'Show replies ({count})'**
  String showReplies(int count);

  /// No description provided for @showMoreReplies.
  ///
  /// In en, this message translates to:
  /// **'Show more replies ({count})'**
  String showMoreReplies(int count);

  /// No description provided for @productDetails.
  ///
  /// In en, this message translates to:
  /// **'Product Details'**
  String get productDetails;

  /// No description provided for @favorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get favorite;

  /// No description provided for @conditionNew.
  ///
  /// In en, this message translates to:
  /// **'✨ New'**
  String get conditionNew;

  /// No description provided for @conditionUsed.
  ///
  /// In en, this message translates to:
  /// **'♻️ Used'**
  String get conditionUsed;

  /// No description provided for @ageGroupFormat.
  ///
  /// In en, this message translates to:
  /// **'{ageGroup}'**
  String ageGroupFormat(String ageGroup);

  /// No description provided for @commentsCount.
  ///
  /// In en, this message translates to:
  /// **'Comments ({count})'**
  String commentsCount(int count);

  /// No description provided for @beFirstToComment.
  ///
  /// In en, this message translates to:
  /// **'Be the first to comment!'**
  String get beFirstToComment;

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get copyLink;

  /// No description provided for @colors.
  ///
  /// In en, this message translates to:
  /// **'Colors / Variants'**
  String get colors;

  /// No description provided for @writeAComment.
  ///
  /// In en, this message translates to:
  /// **'Write a comment...'**
  String get writeAComment;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
