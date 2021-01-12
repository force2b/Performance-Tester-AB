# Platform Cache Performance Testing Proof of Concept
_Written by Michael Smith, December 2020_

The `PerformanceTestServiceController` Apex Class is what defines the tests being conducted. The LWC components simply render that data in the UI with charts.

## Prerequisites:
1. CCI needs to be installed
2. Clone the NPSP repo locally
3. Close this repo locally

## Setup and Configuration
1. From the NPSP repo, create a new `dev` scratch org and deploy the NPSP Unpackaged Metadata into a Scratch Org
   - `cci org scratch dev perftest`
   - `cci flow run config_qa --org perftest`
2. Enable RD2 in the scratch org
   - `cci flow run enable_rd2 --org perftest`
3. Enable Advanced BDI Mapping in the scratch org
   -  This has to be done manually through NPSP Settings -> System -> Advanced Mapping
4. Switch to the close of this repo and use SFDX to push this repo into the scratch org
   - `sfdx force:source:push --forceoverwrite -u Cumulus__perftest`
5. Make sure the "Performance Testing" tab is visible to the User. 

## Starting the Tests
1. Launch the org
2. Open the "Performance Testing" tab
3. Change the seconds interval as desired. The default is to execute the tests every 30 seconds

## Creating or Modifiying the Tests
1. Edit the `PerformanceTestServiceController` and `PerformanceTestService` classes to modify or create new tests as needed.
2. Tests only support an A & B mode. It's not possible to have more than just two test modes. If there is a reason to compare more than two variations of logic, create multiple tests to compare
