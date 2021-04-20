/**
Written January 2021
Michael Smith
Salesforce.com

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/
public without sharing class ProfilingTestServiceController {

    /** ======================================================================================================================
     * The actual tests to perform on the page. See the executeTest() method below to link each test to an apex method.
     * ====================================================================================================================== */
    private static final List<TestConfiguration> testConfig = new List<TestConfiguration>{
        new TestConfiguration('RollupQuery', 'CRLP Custom MetadataType Query', 'SOQL', 'Platform Cache'),
        new TestConfiguration('RollupGrouping-ContactHC', 'CRLP Grouping - Contact Hard Credit', 'Apex', 'Platform Cache'),
        new TestConfiguration('RollupGrouping-AccountHC', 'CRLP Grouping - Account Hard Credit', 'Apex', 'Platform Cache')
        // new TestConfiguration('DataImportMapping', 'Data Import Mapping MetadataType Query', 'SOQL', 'Platform Cache'),
        // new TestConfiguration('TriggerHandler', 'TDTM TriggerHandler Query', 'SOQL', 'Platform Cache'),
        // new TestConfiguration('GlobalDescribeMap', 'getGlobalDescribe', 'Schema', 'Platform Cache (w/o SObjectType)')
    };

    /**
     * @description Returns the full list of Tests. This is called during the LWC page load to return back a structure with the 
     * tests to be executed. The LWC page will use setInterval() to call the ExecuteTest() method in a loop for each individual test
     * in mode A & then mode B.
     * @returns JSON serialized test configuration 
     */
    @AuraEnabled
    public static String getTestConfigMetadata() {

        // Run every test once on page load to "warm" the cache 
        for (TestConfiguration test : testConfig) {
            executeTest(test.TestType, 'A', 'CPU');
            executeTest(test.TestType, 'B', 'CPU');
        }

        // Return the serialized test configuration to the LWC to render in the UI and use for 
        return JSON.serialize(testConfig);
    }

    /**
     * @description Exposed Method to delegate testing for the specified TestName and TestMode
     * @returns The duration in milliseconds.
     * @param testName The name of the test as defined in the TestConfiguration item
     * @param mode A or B
     * @param durationCalcMethod "cpu" (uses Limits.getCpuTime()) or "system" (uses System.currentTimeMillis())
     */
    @AuraEnabled
    public static Double executeTest(String testName, String mode, String durationCalcMethod) {    
        String testNameAndMode = testName + ':' + mode;
        try {
            Long startTime = (durationCalcMethod != 'cpu' ? System.currentTimeMillis() : 0);

            switch on testNameAndMode {
                // when 'TriggerHandler:A' {
                //     triggerHandlerSoql();
                // }
                // when 'TriggerHandler:B' {
                //     triggerHandlerCache();
                // }
                when 'RollupQuery:A' {
                    rollupCmdtSoql();
                }
                when 'RollupQuery:B' {
                    rollupCmdtCache();
                }
                when 'RollupGrouping-ContactHC:A' {
                    crlpGroupingApex(CRLP_RollupProcessingOptions.RollupType.ContactHardCredit);
                }
                when 'RollupGrouping-ContactHC:B' {
                    crlpGroupingCache(CRLP_RollupProcessingOptions.RollupType.ContactHardCredit);
                }
                when 'RollupGrouping-AccountHC:A' {
                    crlpGroupingApex(CRLP_RollupProcessingOptions.RollupType.AccountHardCredit);
                }
                when 'RollupGrouping-AccountHC:B' {
                    crlpGroupingCache(CRLP_RollupProcessingOptions.RollupType.AccountHardCredit);
                }
                // when 'DataImportMapping:A' {
                //     dataImportMappingsSoql();
                // }
                // when 'DataImportMapping:B' {
                //     dataImportMappingsCache();
                // }
                // when 'GlobalDescribeMap:A' {
                //     describeTestA();
                // }
                // when 'GlobalDescribeMap:B' {
                //     describeTestB();
                // }
                when else {
                    throw new AuraHandledException('Unknown Test Type: ' + testNameAndMode);
                }
            }

            return (durationCalcMethod == 'cpu' ? Limits.getCpuTime() : System.currentTimeMillis() - startTime);

            // Not using platform events because these max out at 10k events per day
            // publishEvent(testName, mode, duration);

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description Publish the test completion event
     */
    private static void publishEvent(String testName, String testMode, Long duration) {
        ProfilingTestEvent__e event = new ProfilingTestEvent__e(
            Test_Type__c = testName,
            Test_Mode__c = testMode,
            Duration__c = duration
        );
        System.Eventbus.publish(event);
    }

    // =========================================================================================================
    // INDIVIDUAL TESTING METHODS
    // =========================================================================================================

    // /*************************************************************************************************
    //  * @description Query TriggerHandler__c using SOQL
    //  */
    // private static void triggerHandlerSoql() {
    //     SObject[] results = ProfilingTestService.queryTriggerHandlerRecords();
    // }

    // /**
    //  * @description Query TriggerHandler__c using the Platform Cache
    //  */
    // private static void triggerHandlerCache() {
    //     SObject[] results = (List<SObject>)ProfilingTestService.platformCache.orgCache.get(
    //             ProfilingTestService.TriggerHandlerCache.class, 'dummy'
    //         );
    // }

    /*************************************************************************************************
     * @description Query Rollup__mdt using SOQL
     */
    private static void rollupCmdtSoql(){
        SObject[] results = ProfilingTestService.queryRollupCmdtRecords();
    }

    /**
     * @description Query Rollup__mdt using the Platform Cache
     */
    private static void rollupCmdtCache(){
        Object jsonResult = ProfilingTestService.platformCache.orgCache.get(
            ProfilingTestService.RollupMetadataCache.class, 'dummy'
        );
        System.debug('-- Load TriggerHandlerCache Size: ' +  jsonResult.length());
        
        SObject[] results = (List<SObject>)jsonResult;
    }

    /*************************************************************************************************
     * @description Query Rollup__mdt using SOQL
     */
    private static void crlpGroupingApex(CRLP_RollupProcessingOptions.RollupType rollupType) {
        CRLP_VRollupHandler virtualHandler = new CRLP_VRollupHandler();
        virtualHandler.buildGroupedRollups(rollupType);
        List<CRLP_Rollup> groupedRollups = virtualHandler.getRollupsList();
    }

    /**
     * @description Query Rollup__mdt using the Platform Cache
     */
    private static void crlpGroupingCache(CRLP_RollupProcessingOptions.RollupType rollupType) {
        Object jsonResult = ProfilingTestService.platformCache.orgCache.get(
            ProfilingTestService.RollupGroupingCache.class, rollupType.name()
        );
        System.debug('-- Load CRLP ' + rollupType.name() + ' Size: ' +  jsonResult.length());

        CRLP_Rollup[] results = (List<CRLP_Rollup>)jsonResult;
    }

    // /*************************************************************************************************
    //  * @description Query Data_Import_Field_Mapping__mdt using SOQL
    //  */
    // private static void dataImportMappingsSoql(){
    //     SObject[] results = ProfilingTestService.queryDataImportMappings();
    // }

    // /**
    //  * @description Query Data_Import_Field_Mapping__mdt using the Platform Cache
    //  */
    // private static void dataImportMappingsCache(){
    //     SObject[] results = (List<SObject>)ProfilingTestService.platformCache.orgCache.get(
    //         ProfilingTestService.DataImportMappingsCache.class, 'dummy'
    //     );
    // }


    // /*************************************************************************************************
    //  * @description Test using SObjectDescribe with the default (full) behavior
    //  */
    // private static void describeTestA() {
    //     ProfilingTestService.getGlobalDescribe();
    // }

    // /**
    //  * @description Test using SObectDescribe using the new Deferred behavior
    //  */
    // private static void describeTestB() {
    //     ProfilingTestService.getGlobalDescribeCached();
    // }


    // ===========================================================================================
    // Inner Class structure used to pass the full test configuration data back to the LWC page js
    // ===========================================================================================

    public class TestConfiguration {
        public String TestType;
        public String Label;
        public TestMode ModeA;
        public TestMode ModeB;

        public TestConfiguration(String type, String label, String modeALabel, String modeBLabel) {
            this.TestType = type;
            this.Label = label;
            this.ModeA = new TestMode(modeALabel);
            this.ModeB = new TestMode(modeBLabel);
        }

    }

    public class TestMode {
        public String Label;
        public List<Double> Durations = new List<Double>();
        public Double TotalDuration = 0;
        public Double Counter = 0;
        public Double HighVal = 0;
        public Double LowVal = 0;
        public Double Average = 0;

        public TestMode(String label) {
            this.Label = label;
        }
    }


}
