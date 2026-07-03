
# TestSprite AI Testing Report(MCP)

---

## 1️⃣ Document Metadata
- **Project Name:** sudan_free
- **Date:** 2026-06-26
- **Prepared by:** TestSprite AI Team

---

## 2️⃣ Requirement Validation Summary

#### Test TC001 postauthsignupwithemail
- **Test Code:** [TC001_postauthsignupwithemail.py](./TC001_postauthsignupwithemail.py)
- **Test Error:** Traceback (most recent call last):
  File "/var/task/handler.py", line 258, in run_with_retry
    exec(code, exec_env)
  File "<string>", line 35, in <module>
  File "<string>", line 25, in test_post_auth_sign_up_with_email
AssertionError: Expected 200, got 404

- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/a68b880e-6ff3-4f71-af43-bf3021b90533/1a7f1ce3-b304-4be1-9570-9f3d2f20d432
- **Status:** ❌ Failed
- **Analysis / Findings:** {{TODO:AI_ANALYSIS}}.
---

#### Test TC002 postauthsigninwithemail
- **Test Code:** [TC002_postauthsigninwithemail.py](./TC002_postauthsigninwithemail.py)
- **Test Error:** Traceback (most recent call last):
  File "/var/task/handler.py", line 258, in run_with_retry
    exec(code, exec_env)
  File "<string>", line 56, in <module>
  File "<string>", line 19, in test_post_auth_signin_with_email
AssertionError: Sign up failed with status 404: Not Found

- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/a68b880e-6ff3-4f71-af43-bf3021b90533/07225927-a2ab-4fae-851a-3371813f312e
- **Status:** ❌ Failed
- **Analysis / Findings:** {{TODO:AI_ANALYSIS}}.
---

#### Test TC003 getusersuserid
- **Test Code:** [TC003_getusersuserid.py](./TC003_getusersuserid.py)
- **Test Error:** Traceback (most recent call last):
  File "/var/task/handler.py", line 258, in run_with_retry
    exec(code, exec_env)
  File "<string>", line 47, in <module>
  File "<string>", line 19, in test_get_user_profile_by_userid
AssertionError: SignIn failed with status 404

- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/a68b880e-6ff3-4f71-af43-bf3021b90533/d21d02a0-3f0c-476f-98df-e07380314767
- **Status:** ❌ Failed
- **Analysis / Findings:** {{TODO:AI_ANALYSIS}}.
---

#### Test TC004 putusersuserid
- **Test Code:** [TC004_putusersuserid.py](./TC004_putusersuserid.py)
- **Test Error:** Traceback (most recent call last):
  File "/var/task/handler.py", line 258, in run_with_retry
    exec(code, exec_env)
  File "<string>", line 52, in <module>
  File "<string>", line 17, in test_putusersuserid
AssertionError: SignUp failed: Not Found

- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/a68b880e-6ff3-4f71-af43-bf3021b90533/815550dd-bfa7-4e52-9ac6-3f96399a9f5e
- **Status:** ❌ Failed
- **Analysis / Findings:** {{TODO:AI_ANALYSIS}}.
---

#### Test TC005 postjobs
- **Test Code:** [TC005_postjobs.py](./TC005_postjobs.py)
- **Test Error:** Traceback (most recent call last):
  File "<string>", line 15, in test_postjobs
AssertionError: Sign in failed with status 404

During handling of the above exception, another exception occurred:

Traceback (most recent call last):
  File "/var/task/handler.py", line 258, in run_with_retry
    exec(code, exec_env)
  File "<string>", line 42, in <module>
  File "<string>", line 25, in test_postjobs
AssertionError: Sign in failed: Sign in failed with status 404

- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/a68b880e-6ff3-4f71-af43-bf3021b90533/f93393f1-cd6a-4bbc-8b3a-02a974cb60b2
- **Status:** ❌ Failed
- **Analysis / Findings:** {{TODO:AI_ANALYSIS}}.
---

#### Test TC006 postproposals
- **Test Code:** [TC006_postproposals.py](./TC006_postproposals.py)
- **Test Error:** Traceback (most recent call last):
  File "/var/task/handler.py", line 258, in run_with_retry
    exec(code, exec_env)
  File "<string>", line 114, in <module>
  File "<string>", line 70, in test_postproposals
  File "<string>", line 17, in sign_in_with_email
  File "/var/lang/lib/python3.12/site-packages/requests/models.py", line 1024, in raise_for_status
    raise HTTPError(http_error_msg, response=self)
requests.exceptions.HTTPError: 404 Client Error: Not Found for url: http://localhost:5001/auth/signInWithEmail

- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/a68b880e-6ff3-4f71-af43-bf3021b90533/c153ba27-14dc-42cb-8534-51a93c544d33
- **Status:** ❌ Failed
- **Analysis / Findings:** {{TODO:AI_ANALYSIS}}.
---

#### Test TC007 postposts
- **Test Code:** [TC007_postposts.py](./TC007_postposts.py)
- **Test Error:** Traceback (most recent call last):
  File "/var/task/handler.py", line 258, in run_with_retry
    exec(code, exec_env)
  File "<string>", line 51, in <module>
  File "<string>", line 21, in test_postposts
  File "/var/lang/lib/python3.12/site-packages/requests/models.py", line 1024, in raise_for_status
    raise HTTPError(http_error_msg, response=self)
requests.exceptions.HTTPError: 404 Client Error: Not Found for url: http://localhost:5001/auth/signUpWithEmail

- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/a68b880e-6ff3-4f71-af43-bf3021b90533/5e32ebf4-0ab4-4282-9bbb-deaafb4df051
- **Status:** ❌ Failed
- **Analysis / Findings:** {{TODO:AI_ANALYSIS}}.
---

#### Test TC008 postchats
- **Test Code:** [TC008_postchats.py](./TC008_postchats.py)
- **Test Error:** Traceback (most recent call last):
  File "/var/task/handler.py", line 258, in run_with_retry
    exec(code, exec_env)
  File "<string>", line 115, in <module>
  File "<string>", line 59, in test_postchats
  File "<string>", line 18, in sign_up_email
  File "/var/lang/lib/python3.12/site-packages/requests/models.py", line 1024, in raise_for_status
    raise HTTPError(http_error_msg, response=self)
requests.exceptions.HTTPError: 404 Client Error: Not Found for url: http://localhost:5001/auth/signUpWithEmail

- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/a68b880e-6ff3-4f71-af43-bf3021b90533/a40ef653-0e02-48b4-9a7a-5b179e2dcd3b
- **Status:** ❌ Failed
- **Analysis / Findings:** {{TODO:AI_ANALYSIS}}.
---

#### Test TC009 postpayments
- **Test Code:** [TC009_postpayments.py](./TC009_postpayments.py)
- **Test Error:** Traceback (most recent call last):
  File "/var/task/handler.py", line 258, in run_with_retry
    exec(code, exec_env)
  File "<string>", line 146, in <module>
  File "<string>", line 18, in test_postpayments
AssertionError: SignUp failed: Not Found

- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/a68b880e-6ff3-4f71-af43-bf3021b90533/31d8223f-5097-4679-9f88-8645da500b50
- **Status:** ❌ Failed
- **Analysis / Findings:** {{TODO:AI_ANALYSIS}}.
---

#### Test TC010 postreviews
- **Test Code:** [TC010_postreviews.py](./TC010_postreviews.py)
- **Test Error:** Traceback (most recent call last):
  File "/var/task/handler.py", line 258, in run_with_retry
    exec(code, exec_env)
  File "<string>", line 132, in <module>
  File "<string>", line 18, in test_postreviews
AssertionError: Sign up failed: 404 Not Found

- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/a68b880e-6ff3-4f71-af43-bf3021b90533/3ceaba61-6282-48a3-aaba-cd482a6a6199
- **Status:** ❌ Failed
- **Analysis / Findings:** {{TODO:AI_ANALYSIS}}.
---


## 3️⃣ Coverage & Matching Metrics

- **0.00** of tests passed

| Requirement        | Total Tests | ✅ Passed | ❌ Failed  |
|--------------------|-------------|-----------|------------|
| ...                | ...         | ...       | ...        |
---


## 4️⃣ Key Gaps / Risks
{AI_GNERATED_KET_GAPS_AND_RISKS}
---