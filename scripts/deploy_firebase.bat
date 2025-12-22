@echo off
echo Deploying ISET Restaurant Backend to Firebase...

echo.
echo 1. Installing Firebase Functions dependencies...
cd firebase\functions
call npm install
cd ..\..

echo.
echo 2. Deploying Firestore security rules...
call firebase deploy --only firestore:rules

echo.
echo 3. Deploying Firestore indexes...
call firebase deploy --only firestore:indexes

echo.
echo 4. Deploying Cloud Functions...
call firebase deploy --only functions

echo.
echo 5. Deploying Web hosting (optional)...
call firebase deploy --only hosting

echo.
echo Firebase deployment completed successfully!
echo.
echo Your backend is now live and ready for production use.

pause