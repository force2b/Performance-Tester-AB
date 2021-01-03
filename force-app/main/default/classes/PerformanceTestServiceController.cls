public without sharing class PerformanceTestServiceController {

    private static Long startTime;
    private static Long duration = 0;

    private static PerformanceTestService.CacheUtil platformCache = new PerformanceTestService.CacheUtil();

    /**
     * @description Returns the full list of Tests
     */
    @AuraEnabled
    public static String getTestConfigMetadata() {

        // Initialize the Cache so they're not counting the cold query time
        rollupCmdtCache();
        triggerHandlerCache();

        return JSON.serialize(new List<TestConfiguration>{
            new TestConfiguration('TriggerHandler', 'TDTM TriggerHandler Query', 'SOQL', 'Platform Cache'),
            new TestConfiguration('RollupsQuery', 'CRLP Custom MetadataType Query', 'SOQL', 'Platform Cache'),
            new TestConfiguration('DataImportMapping', 'Data Import Mapping MetadataType Query', 'SOQL', 'Platform Cache'),
            new TestConfiguration('DescribeTest', 'SObject Describe', 'Default', 'Deferred')
        });
    }

    /**
     * @description Exposed Method to delegate testing for type mode A
     */
    @AuraEnabled
    public static Double ExecuteTest(String testName, String mode) {
        String testNameAndMode = testName + ':' + mode;
        try {
            switch on testNameAndMode {
                when 'TriggerHandler:A' {
                    triggerHandlerSoql();
                }
                when 'TriggerHandler:B' {
                    triggerHandlerCache();
                }
                when 'RollupsQuery:A' {
                    rollupCmdtSoql();
                }
                when 'RollupsQuery:B' {
                    rollupCmdtCache();
                }
                when 'DataImportMapping:A' {
                    dataImportMappingsSoql();
                }
                when 'DataImportMapping:B' {
                    dataImportMappingsCache();
                }
                when 'DescribeTest:A' {
                    describeTestA();
                }
                when 'DescribeTest:B' {
                    describeTestB();
                }
                when else {
                    throw new AuraHandledException('Unknown Test Type: ' + testNameAndMode);
                }
            }

            // Not using platform events because these max out at 10k events per day
            // publishEvent(testName, mode, duration);

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return duration;
    }

    /**
     * @description Publish the test completion event
     */
    private static void publishEvent(String testName, String testMode, Long duration) {
        PerformanceTestEvent__e event = new PerformanceTestEvent__e(
            Test_Type__c = testName,
            Test_Mode__c = testMode,
            Duration__c = duration
        );
        System.Eventbus.publish(event);
    }

    // =========================================================================================================
    // INDIVIDUAL TESTING METHODS
    // =========================================================================================================

    /*************************************************************************************************
     * @description Query TriggerHandler__c using SOQL
     */
    private static void triggerHandlerSoql() {
        startTime = System.currentTimeMillis();
        Trigger_Handler__c[] results = PerformanceTestService.queryTriggerHandlerRecords();
        duration = System.currentTimeMillis() - startTime;
    }

    /**
     * @description Query TriggerHandler__c using SOQL
     */
    private static void triggerHandlerCache() {
        startTime = System.currentTimeMillis();

        Trigger_Handler__c[] results = (List<Trigger_Handler__c>)platformCache.orgCache.get(
                PerformanceTestService.TriggerHandlerCache.class, 'dummy'
            );
        duration = System.currentTimeMillis() - startTime;
    }

    /*************************************************************************************************
     * @description Query Rollup__mdt using SOQL
     */
    private static void rollupCmdtSoql(){
        startTime = System.currentTimeMillis();
        Rollup__mdt[] results = PerformanceTestService.queryRollupCmdtRecords();
        duration = System.currentTimeMillis() - startTime;
    }

    /**
     * @description Query Rollup__mdt using SOQL
     */
    private static void rollupCmdtCache(){
        startTime = System.currentTimeMillis();
        Rollup__mdt[] results = (List<Rollup__mdt>)platformCache.orgCache.get(
            PerformanceTestService.RollupMetadataCache.class, 'dummy'
        );
        duration = System.currentTimeMillis() - startTime;
    }

    /*************************************************************************************************
     * @description Query Data_Import_Field_Mapping__mdt using SOQL
     */
    private static void dataImportMappingsSoql(){
        startTime = System.currentTimeMillis();
        Data_Import_Field_Mapping__mdt[] results = PerformanceTestService.queryDataImportMappings();
        duration = System.currentTimeMillis() - startTime;
    }

    /**
     * @description Query Data_Import_Field_Mapping__mdt using SOQL
     */
    private static void dataImportMappingsCache(){
        startTime = System.currentTimeMillis();
        Data_Import_Field_Mapping__mdt[] results = (List<Data_Import_Field_Mapping__mdt>)platformCache.orgCache.get(
            PerformanceTestService.DataImportMappingsCache.class, 'dummy'
        );
        duration = System.currentTimeMillis() - startTime;
    }


    /*************************************************************************************************
     * @description Test using SObjectDescribe with the default (full) behavior
     */
    private static void describeTestA() {
        startTime = System.currentTimeMillis();
        PerformanceTestService.getObjectDescribeFull();
        duration = System.currentTimeMillis() - startTime;
    }

    /**
     * @description Test using SObectDescribe using the new Deferred behavior
     */
    private static void describeTestB() {
        startTime = System.currentTimeMillis();
        PerformanceTestService.getObjectDescribeDeferred();
        duration = System.currentTimeMillis() - startTime;
    }

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
