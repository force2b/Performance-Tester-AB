# A-B Profiling Test Utility
_Written by Michael Smith, January 2021_

The `ProfilingTestServiceController` Apex Class is what defines the tests being conducted. The LWC components simply renders that data in the UI with charts. The [ChartJS library](https://salesforcelabs.github.io/LightningWebChartJS/) is used to render the charts in the UI. In addition to the Apex and LWC's needed to perform and render the test, the repo contains a 3MB cache partition that the apex class uses in the tests.

![Main Image](https://github.com/force2b/Performance-Tester-AB/blob/main/images/PerfTestPage.png)

## Prerequisites:
1. SFDX needs to be installed. CCI is optional, but useful.
2. Clone the NPSP repo locally
3. Close this repo locally

### NPSP Dependency
- Using this with NPSP is completely **optional**.
- It was primariliy built to test certain features that rely on NPSP, however that dependency can be easily removed by changing the tests that execute in the `ProfilingTestServiceController` and `ProfilingTestService` apex classes. 

## Setup and Configuration (if CCI is used with NPSP)
1. Modify the default `orgs/dev.json` scratch org definition to add the following to the config, which enables Platform Cache in the org:
   - `"features": [ "PlatformCache" ],`
1. From the NPSP repo, create a new `dev` scratch org and deploy the NPSP Unpackaged Metadata into a Scratch Org. Note that this extends the expiration date to 14 days to allow for additional testing time. Adjust as needed.
   - `cci org scratch dev perftest --days 14` 
   - `cci flow run config_qa --org perftest`
2. Enable RD2 in the scratch org
   - `cci flow run enable_rd2 --org perftest`
3. Enable Advanced BDI Mapping in the scratch org
   -  This has to be done manually through NPSP Settings -> System -> Advanced Mapping
4. Switch to the close of this repo and use SFDX to push this repo into the scratch org
   - `sfdx force:source:push --forceoverwrite -u Cumulus__perftest`

## Setup and Configuration (without NPSP)
1. After downloading this repo locally, create a new SFDX project for this in Visual Studio Code (or IntelliJ)
2. Modify the `ProfilingTestServiceController` and `ProfilingTestService` classes locally to remove references to any NPSP custom objects.
3. Create a new scratch org using the `config/project-scratch-def.json` definition (this enables Platform Cache in the org)
   - `sfdx force:org:create -f config/project-scratch-def.json -a perftest`
4. Push the source into the scratch org
   - `sfdx force:source:push -u perftest`

## Starting the Tests
1. Launch the org
2. Open the "Profiling Test" tab
3. Change the seconds interval as desired. The default is to execute the tests every 30 seconds

## Creating or Modifiying the Tests
1. Edit the `ProfilingTestServiceController` and `ProfilingTestService` classes to modify or create new tests as needed.
2. Tests only support an A & B mode. It's not possible to have more than just two test modes. If there is a reason to compare more than two variations of logic, create multiple tests to compare
