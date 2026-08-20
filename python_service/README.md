# RideMate Location Service

Run this service in a separate terminal before using live destination search or shared-ride matching:

```powershell
cd C:\Ride_Mate_AI\python_service
py -m pip install -r requirements.txt
py app.py
```

It starts at `http://localhost:8000`.

The matching process uses a BallTree/Haversine radius filter for exact pickup and destination distance, then a pre-trained SentenceTransformer to improve matching of place-name variants. The model is off by default so startup is fast. To allow its initial download and enable semantic ranking on a connected computer, run:

```powershell
$env:RIDEMATE_ALLOW_MODEL_DOWNLOAD = '1'
$env:RIDEMATE_ENABLE_EMBEDDINGS = '1'
py app.py
```
