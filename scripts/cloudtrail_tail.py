#!/usr/bin/env python3
import boto3
import time
from datetime import datetime, timedelta

def format_age(event_time):
    """Format age like kubectl (e.g., 0s, 3m, 1h)"""
    # Use local time for both - much simpler
    now = datetime.now()
    event_local = event_time.replace(tzinfo=None) if event_time.tzinfo else event_time
    
    diff = now - event_local
    total_seconds = int(diff.total_seconds())
    
    # Handle negative time (future events)
    if total_seconds < 0:
        total_seconds = abs(total_seconds)
    
    if total_seconds < 60:
        return f"{total_seconds}s"
    elif total_seconds < 3600:
        minutes = total_seconds // 60
        return f"{minutes}m"
    elif total_seconds < 86400:
        hours = total_seconds // 3600
        minutes = (total_seconds % 3600) // 60
        if minutes > 0:
            return f"{hours}h{minutes}m"
        else:
            return f"{hours}h"
    else:
        days = total_seconds // 86400
        hours = (total_seconds % 86400) // 3600
        if hours > 0:
            return f"{days}d{hours}h"
        else:
            return f"{days}d"

session = boto3.Session(profile_name='dev_6742')
client = session.client('cloudtrail')
last_time = datetime.utcnow()  # Start from now, not 1 minute ago

print("CloudTrail Live Stream - Press Ctrl+C to stop")
print("Waiting for new events...")
print("-" * 70)

try:
    while True:
        events = client.lookup_events(StartTime=last_time)['Events']
        
        for event in reversed(events):
            age = format_age(event['EventTime'])
            ts = event['EventTime'].strftime('%H:%M:%S')
            name = event['EventName']
            source = event['EventSource'].replace('.amazonaws.com', '')
            user = event.get('Username', 'system')[:15]
            
            # Parse CloudTrailEvent for more details
            msg = ""
            try:
                import json
                ct_event = json.loads(event.get('CloudTrailEvent', '{}'))
                
                # Get error info
                if ct_event.get('errorCode'):
                    error_msg = ct_event.get('errorMessage', ct_event['errorCode'])
                    msg = f" ERROR: {error_msg}"
                # Get resource info
                elif event.get('Resources'):
                    resource = event['Resources'][0].get('ResourceName', '')
                    if resource:
                        msg = f" -> {resource}"
                # Get request parameters for context
                elif ct_event.get('requestParameters'):
                    req = ct_event['requestParameters']
                    if isinstance(req, dict):
                        # Extract meaningful params
                        if 'name' in req:
                            msg = f" name={req['name']}"
                        elif 'clusterName' in req:
                            msg = f" cluster={req['clusterName']}"
                        elif 'instanceIds' in req:
                            msg = f" instances={len(req['instanceIds'])}"
                        elif 'groupNames' in req:
                            msg = f" groups={len(req['groupNames'])}"
                            
            except:
                # Fallback to simple resource info
                if event.get('Resources'):
                    resource = event['Resources'][0].get('ResourceName', '')
                    if resource:
                        msg = f" -> {resource[:25]}"
            
            print(f"{age:>6} {ts} {source:15} {name:30} {user:18}{msg}")
            
        if events:
            last_time = events[0]['EventTime']
            
        time.sleep(5)
        
except KeyboardInterrupt:
    print("\nStopped")
