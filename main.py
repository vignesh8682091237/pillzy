from fastapi import FastAPI, HTTPException, UploadFile, File, Form, Request
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware
import firebase_admin
from firebase_admin import credentials, firestore, storage
import os
import uuid

import json

app = FastAPI(title="Pillzy Backend API")

@app.get("/")
async def root():
    return {"status": "online", "message": "Pillzy Backend is running!"}

# Add CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Firebase Initialization
try:
    # Try loading from environment variable first (for cloud deployment)
    firebase_key = os.environ.get("FIREBASE_KEY")
    if firebase_key:
        cred_dict = json.loads(firebase_key)
        cred = credentials.Certificate(cred_dict)
    else:
        # Fallback to local file
        service_account_path = os.path.join(os.path.dirname(__file__), "viji-project-6fa54-firebase-adminsdk-fbsvc-5dc3d2f88a.json")
        if os.path.exists(service_account_path):
            cred = credentials.Certificate(service_account_path)
        else:
            raise Exception("No Firebase credentials found (env or file)")

    firebase_admin.initialize_app(cred, {
        'storageBucket': 'viji-project-6fa54.appspot.com'
    })
    db = firestore.client()
    bucket = storage.bucket()
    print("Firebase initialized successfully!")
except Exception as e:
    print(f"Error initializing Firebase: {e}")
    db = None
    bucket = None

@app.post("/upload-image")
async def upload_image(file: UploadFile = File(...)):
    if not bucket:
        raise HTTPException(status_code=500, detail="Firebase Storage not initialized")
    
    try:
        file_extension = os.path.splitext(file.filename)[1]
        unique_filename = f"{uuid.uuid4()}{file_extension}"
        blob = bucket.blob(f"uploads/{unique_filename}")
        
        # Read file contents
        contents = await file.read()
        content_type = getattr(file, "content_type", "image/jpeg")
        
        # Upload the file
        blob.upload_from_string(
            contents,
            content_type=content_type
        )
        
        # Make it public
        try:
            blob.make_public()
        except:
            pass
        
        return {"status": "success", "url": blob.public_url}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

class Medicine(BaseModel):
    name: str
    dosage: str
    time: str
    user_id: str
    frequency: str = ""
    times: list = []
    photo: str = ""

class UserProfile(BaseModel):
    email: str
    name: str
    dob: str
    age: str = ""
    gender: str = ""
    blood_group: str = ""
    phone: str = ""
    address: str = ""
    photo: str = ""
    emergency_name: str = ""
    emergency_relationship: str = ""
    emergency_gender: str = ""
    emergency_phone: str = ""
    emergency_email: str = ""
    languageCode: str = "en"
    emergency_address: str = ""

class AdherenceRecord(BaseModel):
    user_id: str
    medicine_id: str
    medicine_name: str
    status: str  # e.g., "taken", "skipped"
    timestamp: str  # ISO format date-time

@app.get("/")
async def root():
    return {"message": "Welcome to Pillzy Backend API"}

@app.post("/add-medicine")
async def add_medicine(medicine: Medicine):
    if not db:
        raise HTTPException(status_code=500, detail="Firebase not initialized")
    
    try:
        # Add to Firestore
        doc_ref = db.collection("medicines").document()
        doc_ref.set(medicine.model_dump())
        return {"status": "success", "id": doc_ref.id}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/get-medicines/{user_id}")
async def get_medicines(user_id: str):
    if not db:
        raise HTTPException(status_code=500, detail="Firebase not initialized")
    
    try:
        docs = db.collection("medicines").where("user_id", "==", user_id).stream()
        medicines = []
        for doc in docs:
            data = doc.to_dict()
            data['id'] = doc.id
            medicines.append(data)
        return {"medicines": medicines}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/update-medicine/{med_id}")
async def update_medicine(med_id: str, medicine: Medicine):
    if not db:
        raise HTTPException(status_code=500, detail="Firebase not initialized")
    
    try:
        db.collection("medicines").document(med_id).set(medicine.model_dump(), merge=True)
        return {"status": "success", "message": "Medicine updated successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/delete-medicine/{med_id}")
async def delete_medicine(med_id: str):
    if not db:
        raise HTTPException(status_code=500, detail="Firebase not initialized")
    
    try:
        db.collection("medicines").document(med_id).delete()
        return {"status": "success", "message": "Medicine deleted successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/register")
async def register_user(user: UserProfile):
    if not db:
        raise HTTPException(status_code=500, detail="Firebase not initialized")
    
    try:
        db.collection("users").document(user.email).set(user.model_dump())
        return {"status": "success", "message": "User registered successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/update-profile")
async def update_user(user: UserProfile):
    if not db:
        raise HTTPException(status_code=500, detail="Firebase not initialized")
    
    try:
        db.collection("users").document(user.email).set(user.model_dump(), merge=True)
        return {"status": "success", "message": "Profile updated successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/login")
async def login_user(login_data: dict):
    if not db:
        raise HTTPException(status_code=500, detail="Firebase not initialized")
    
    email = login_data.get("email")
    dob = login_data.get("dob")
    
    try:
        doc = db.collection("users").document(email).get()
        if doc.exists:
            user_data = doc.to_dict()
            if user_data.get("dob") == dob:
                return {"status": "success", "user": user_data}
            else:
                raise HTTPException(status_code=401, detail="Invalid date of birth")
        else:
            raise HTTPException(status_code=404, detail="User not found")
    except HTTPException as he:
        raise he
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/log-adherence")
async def log_adherence(record: AdherenceRecord):
    if not db:
        raise HTTPException(status_code=500, detail="Firebase not initialized")
    
    try:
        db.collection("adherence").add(record.model_dump())
        return {"status": "success", "message": "Adherence logged successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/get-progress/{user_id}")
async def get_progress(user_id: str):
    if not db:
        raise HTTPException(status_code=500, detail="Firebase not initialized")
    
    try:
        docs = db.collection("adherence").where("user_id", "==", user_id).stream()
        history = []
        for doc in docs:
            history.append(doc.to_dict())
        return {"status": "success", "history": history}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/verify-face")
async def verify_face(request: Request):
    if not bucket:
        raise HTTPException(status_code=500, detail="Firebase Storage not initialized")
    
    try:
        form_data = await request.form()
        email = form_data.get("email", "guest")
        file = form_data.get("file")
        
        if file:
            # Try to upload but don't fail if it doesn't work
            try:
                file_data = await file.read()
                file_extension = os.path.splitext(file.filename)[1] if file.filename else ".jpg"
                content_type = getattr(file, "content_type", "image/jpeg")
                unique_filename = f"verify_{uuid.uuid4()}{file_extension}"
                blob = bucket.blob(f"verification/{email}/{unique_filename}")
                blob.upload_from_string(file_data, content_type=content_type)
            except:
                pass
        
        # ALWAYS return success to bypass verification
        return {"status": "success", "url": None, "verified": True}
    except Exception as e:
        # Even in outer catch, return success for now as requested
        return {"status": "success", "verified": True}

if __name__ == "__main__":
    import uvicorn
    # log_level="error" hides the INFO logs
    uvicorn.run(app, host="0.0.0.0", port=8000, log_level="error")
