# Government Officials Data - Setup Guide

This app uses a **hybrid approach** to fetch current government officials data without requiring API keys or authentication.

## Data Sources

### Static Data (No Network Required)
- **President** - Updated with app releases
- **Vice President** - Updated with app releases  
- **State Governors** - Updated with app releases

Source: `assets/government_officials.json`

### API Data (No Authentication)
- **U.S. Senators** - Fetched from whoismyrepresentative.com
- **U.S. Representatives** - Fetched from whoismyrepresentative.com

Source: [whoismyrepresentative.com](https://whoismyrepresentative.com/api)

## Benefits of This Approach

✅ **No API Keys** - No security concerns, no key management  
✅ **No DOS Risk** - Free public API with no authentication  
✅ **Works Offline** - President, VP, and Governors available without network  
✅ **Always Current** - Senators and Representatives fetched in real-time  
✅ **No Quotas** - No rate limits or usage restrictions  
✅ **Simple** - No backend infrastructure needed  

## How It Works

1. **During Onboarding**: User enters zip code
2. **Zip → State Mapping**: App determines state from zip code
3. **Static Data**: President, VP, Governor loaded from JSON file
4. **API Calls**: Senators and Representatives fetched from whoismyrepresentative.com
5. **Database Update**: All officials written to local database for quiz questions

## Updating Static Data

The static data file should be updated when:
- New President/VP takes office (every 4 years)
- Governors change (ongoing, varies by state)
- Major app releases

### Update Process

1. **Get Current Governors** from [Wikipedia](https://en.wikipedia.org/wiki/List_of_current_United_States_governors)
2. **Update `assets/government_officials.json`**:
   ```json
   {
     "lastUpdated": "2026-02-02",
     "president": "Donald John Trump",
     "vicePresident": "James David Vance",
     "governors": {
       "Alabama": "Kay Ivey",
       ...
     }
   }
   ```
3. **Test** the app with onboarding flow
4. **Release** new app version

## API Details

### whoismyrepresentative.com

**Endpoints:**
- Senators: `GET /getall_sens_bystate.php?state=CA&output=json`
- Representatives: `GET /getall_reps_byzip.php?zip=12345&output=json`

**Response Format:**
```json
{
  "results": [
    {
      "name": "Senator Name",
      "party": "D",
      "state": "CA",
      ...
    }
  ]
}
```

**Attribution:** As required by whoismyrepresentative.com, we acknowledge their free API service.

## Fallback Behavior

If API calls fail:
- App uses placeholder text (e.g., "Your U.S. Senator")
- Sets `needsManualVerification` flag to `true`
- App continues to work normally

## Troubleshooting

### "State not found" Error
- Check that state name in JSON matches exactly
- Ensure proper capitalization

### Network Errors for Senators/Representatives
- API may be temporarily down
- User may be offline
- App will use placeholders and continue

### Outdated Governor Information
- Update `assets/government_officials.json`
- Rebuild and release app

## Additional Resources

- [whoismyrepresentative.com API Docs](https://whoismyrepresentative.com/api)
- [Wikipedia Governors List](https://en.wikipedia.org/wiki/List_of_current_United_States_governors)
- [Congress.gov](https://www.congress.gov/) - Official source for congressional info
