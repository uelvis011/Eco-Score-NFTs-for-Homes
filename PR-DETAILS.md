# Carbon Footprint Tracking Feature

## Overview
Added comprehensive carbon footprint tracking capabilities to the Eco-Score NFTs for Homes smart contract. This independent feature enables homeowners to monitor their monthly energy usage, calculate CO2 emissions, and earn rewards for carbon reduction achievements.

## Technical Implementation
**New Constants:**
- `carbon-report-cooldown`: 30-day reporting interval (2190 blocks)
- `carbon-reduction-threshold`: 10% minimum reduction for achievements
- Error constants for carbon tracking validation

**Key Functions and Data Structures:**
- `carbon-footprint-data` map: Stores monthly usage data, CO2 calculations, and tracking status
- `carbon-reduction-achievements` map: Records achievement periods and rewards
- `enable-carbon-tracking()`: Activates tracking for a home NFT
- `report-monthly-usage()`: Records electricity, gas, water, and waste data
- `calculate-co2-emissions()`: Converts usage to CO2 tons using emission factors
- `claim-carbon-reduction-achievement()`: Rewards users for meeting reduction targets

**CO2 Calculation Formula:**
- Electricity: kWh × 0.4kg CO2
- Gas: units × 2kg CO2  
- Water: units × 0.3kg CO2
- Waste: kg × 0.5kg CO2

## Testing & Validation
- ✅ Contract passes clarinet check (25 minor warnings for unchecked data - standard)
- ✅ All npm tests successful
- ✅ CI/CD pipeline configured with GitHub Actions
- ✅ Clarity v3 compliant with proper error handling
- ✅ Independent feature with no cross-contract dependencies
