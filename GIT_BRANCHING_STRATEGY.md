# 📌 Git Branching Strategy for Project

## 📊 Branching Diagram
```
          main  
           │  
    ─────►●───────────►●───────────►●  (Stable production)
           │          │            │
    ─────►●───────────►●───────────►●  (testing)
           │           │           │
    ┌────────────────────────────────────────────────┐  
    │                                                │  
  backend-develop                            frontend-develop  
    │                                         │  
    ├── feature/auth-backend                  ├── feature/auth-frontend   
    ├── feature/chat-backend                  ├── feature/chat-frontend   
    ├── feature/api-refactor                  ├── feature/ui-fixes  
    │                                         │  
    └── hotfix/backend                        └── hotfix/frontend  
```

## 📌 Explanation
- **`main`** → Stable production branch.
- **`testing`** → Pre-release branch for final QA before merging into `main`.
- **`backend-develop`** → All backend feature branches merge here.
- **`frontend-develop`** → All frontend feature branches merge here.
- **`feature/*`** → Separate feature branches for backend & frontend.
- **`hotfix/*`** → Urgent bug fixes merged into `main` & `develop`.

---

## 🔄 Workflow
1️⃣ Developers create **feature branches** for backend & frontend separately.
2️⃣ Completed features merge into **backend-develop** or **frontend-develop**.
3️⃣ Both **backend-develop & frontend-develop** merge into **testing** for QA.
4️⃣ After successful testing, **merge `testing` into `main`** for production.
4️⃣ Delete the feature branch after merging to keep the repository clean. It prevents clutter and confusion.

---

## 🛠 Git Commands & Explanation

### **🔹 Creating Feature Branches**
```sh
git checkout backend-develop
# Update branch
git pull origin backend-develop
# Create feature branch
git checkout -b feature/api-refactor
# Push branch
git push -u origin feature/api-refactor
```
👉 **Creates a new backend feature branch from `backend-develop` and pushes it.**

```sh
git checkout frontend-develop
git pull origin frontend-develop
git checkout -b feature/ui-fixes
git push -u origin feature/ui-fixes
```
👉 **Creates a new frontend feature branch from `frontend-develop`.**

---

### **🔹 Merging into Develop Branches**
```sh
git checkout backend-develop
git merge feature/api-refactor
git push origin backend-develop
```
👉 **Merges backend feature into `backend-develop`.**

```sh
git checkout frontend-develop
git merge feature/ui-fixes
git push origin frontend-develop
```
👉 **Merges frontend feature into `frontend-develop`.**

---

### **🔹 Merging to Testing**
```sh
git checkout testing
git merge backend-develop
git merge frontend-develop
git push origin testing
```
👉 **Combines `backend-develop` and `frontend-develop` for testing.**

---

### **🔹 Merging to Main for Deployment**
```sh
git checkout main
git merge testing
git push origin main
```
👉 **Deploys the tested code to production.**

---

### **🔹 Handling Merge Conflicts**
```sh
git merge feature/new-feature  # Attempt to merge
git status                      # Identify conflicts
# Manually resolve conflicts in files
git add resolved-file.js        # Mark resolved files
git commit -m "Resolve merge conflicts"
git push origin develop
```
👉 **Fixes conflicts manually before merging.**

---

### **🔹 Deleting Merged Branches**
```sh
git branch -d feature/new-feature  # Delete locally
git push origin --delete feature/new-feature  # Delete remotely
```
👉 **Removes feature branches after merging.**

---

🔥 Hotfix Workflow Example

Scenario: Fixing a Critical Bug in Production

Step 1: Create a Hotfix Branch

git checkout main
git pull origin main
git checkout -b hotfix/critical-login-fix

👉 Creates a hotfix branch from main.

Step 2: Apply the Fix & Commit

# Make necessary code changes
git add affected-file.js
git commit -m "Fix login issue causing user session timeout"
git push origin hotfix/critical-login-fix

👉 Commits and pushes the fix to the hotfix branch.

Step 3: Merge Hotfix into main & Deploy

git checkout main
git merge hotfix/critical-login-fix
git push origin main

👉 Merges the hotfix into main for immediate production deployment.

Step 4: Sync the Fix with Develop Branches

git checkout backend-develop
git merge main
git push origin backend-develop

git checkout frontend-develop
git merge main
git push origin frontend-develop

👉 Ensures the fix is included in ongoing development.

Step 5: Delete the Hotfix Branch

git branch -d hotfix/critical-login-fix
git push origin --delete hotfix/critical-login-fix

👉 Removes the hotfix branch after deployment.

---

## 🎯 Example Workflow
### **Scenario:** Adding User Authentication

#### **Step 1: Backend Developer Creates a Feature Branch**
```sh
git checkout backend-develop
git pull origin backend-develop
git checkout -b feature/auth-backend
git push -u origin feature/auth-backend
```

#### **Step 2: Frontend Developer Creates a Feature Branch**
```sh
git checkout frontend-develop
git pull origin frontend-develop
git checkout -b feature/auth-frontend
git push -u origin feature/auth-frontend
```

#### **Step 3: Backend Developer Completes Work & Merges to Develop**
```sh
git checkout backend-develop
git merge feature/auth-backend
git push origin backend-develop
```

#### **Step 4: Frontend Developer Completes Work & Merges to Develop**
```sh
git checkout frontend-develop
git merge feature/auth-frontend
git push origin frontend-develop
```

#### **Step 5: Testing Branch Integration**
```sh
git checkout testing
git merge backend-develop
git merge frontend-develop
git push origin testing
```

#### **Step 6: Deploy to Main**
```sh
git checkout main
git merge testing
git push origin main
```

✅ **Authentication feature is now live in production!** 🚀

