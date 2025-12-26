#!/usr/bin/env python3
import boto3
import time
from datetime import datetime, timedelta

session = boto3.Session(profile_name='dev_6742')
client = session.client('cloudtrail')
last_time = datetime.utcnow() - timedelta(minutes=1)

print("CloudTrail Live Stream - Press Ctrl+C to stop")
print("-" * 70)

try:
    while True:
        events = client.lookup_events(StartTime=last_time)['Events']
        
        for event in reversed(events):
            ts = event['EventTime'].strftime('%H:%M:%S')
            name = event['EventName']
            source = event['EventSource'].replace('.amazonaws.com', '')
            user = event.get('Username', 'system')[:15]
            
            # Get error message or resource info
            msg = ""
            if 'ErrorMessage' in event:
                msg = f" ERROR: {event['ErrorMessage'][:50]}"
            elif 'Resources' in event and event['Resources']:
                resource = event['Resources'][0].get('ResourceName', '')
                if resource:
                    msg = f" -> {resource[:30]}"
            
            print(f"{ts} {source:12} {name:25} {user}{msg}")
            
        if events:
            last_time = events[0]['EventTime']
            
        time.sleep(5)
        
except KeyboardInterrupt:
    print("\nStopped")
