# Firebase Database Setup

To ensure proper sorting and querying of sensor data by timestamp, you need to set up an index on the `timestamp` field in your Firebase Realtime Database.

## Setting up the Index

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `final-base-99d49`
3. Navigate to "Realtime Database" in the left sidebar
4. Click on the "Rules" tab
5. Replace the existing rules with the following:

```json
{
  "rules": {
    ".read": true,
    ".write": true,
    "sensorData": {
      ".indexOn": ["timestamp"]
    }
  }
}
```

6. Click "Publish" to save the rules

## Why This Is Needed

The `.indexOn` rule tells Firebase to create an index on the `timestamp` field for the `sensorData` path. This allows for efficient querying and sorting of data based on the timestamp, which is essential for retrieving the latest sensor readings correctly.

Without this index, Firebase has to scan all records to find those matching your query criteria, which can lead to inconsistent results, especially when dealing with large datasets.

## Important Notes About Timestamps

In this application:

1. Timestamps are stored as numeric values (not strings)
2. The app is configured to handle both string and numeric timestamp values
3. For proper sorting, make sure all new data has a numeric timestamp field

## Handling Special Values

The app has been updated to handle special values:

- Distance value of -1 is displayed as "N/A" in the UI
- pH value of null is displayed as "N/A" in the UI

## Verifying the Setup

After setting up the index, you should see improved performance and consistency when querying sensor data by timestamp. The app should now consistently retrieve the latest sensor data based on the timestamp value.
