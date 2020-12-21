public without sharing class PerformanceTestServiceController {

    private static Long startTime;
    private static Long duration = 0;

    /**
     * @description Collection of Tests:
     * Key:TestName
     * List[0]: Test Label for UI
     * List[1]: Test Mode A Label
     * List[2]: Test Mode B Label
     */
    // private static Map<String, Map<String, String>> testConfigMetadata = new Map<String, Map<String, String>>{
    //     'TriggerHandler' => new Map<String, String>{
    //         'TestLabel' => 'TDTM TriggerHandler Query',
    //         'ModeALabel' => 'SOQL',
    //         'ModeBLabel' => 'PlatformCache'
    //     },
    //     'RollupsQuery' => new Map<String, String>{
    //         'TestLabel' => 'CRLP Custom Metadata Type Query',
    //         'ModeALabel' => 'SOQL',
    //         'ModeBLabel' => 'PlatformCache'
    //     },
    //     'Describe' => new Map<String, String>{
    //         'TestLabel' => 'SObject Describe',
    //         'ModeALabel' => 'Full',
    //         'ModeBLabel' => 'Partial'
    //     }
    // };

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
            new TestConfiguration('DescribeTest', 'UTIL_Describe', 'Default', 'Deferred')
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
                when 'RollupsQuery:A' {
                    rollupCmdtSoql();
                }
                when 'DescribeTest:A' {
                    describeTestA();
                }
                when 'TriggerHandler:B' {
                    triggerHandlerCache();
                }
                when 'RollupsQuery:B' {
                    rollupCmdtCache();
                }
                when 'DescribeTest:B' {
                    describeTestB();
                }
                when else {
                    throw new AuraHandledException('Unknown Test Type: ' + testNameAndMode);
                }
            }

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

    /**
     * @description Query TriggerHandler__c using SOQL
     */
    private static void triggerHandlerSoql() {
        startTime = System.currentTimeMillis();
        Trigger_Handler__c[] results = queryTriggerHandlerRecords();
        duration = System.currentTimeMillis() - startTime;
    }

    /**
     * @description Query TriggerHandler__c using SOQL
     */
    private static void triggerHandlerCache() {
        startTime = System.currentTimeMillis();

        UTIL_PlatformCache platformCache = UTIL_PlatformCache.getInstance();
        if (platformCache.isOrgCacheAvailable) {
            Trigger_Handler__c[] results = (List<Trigger_Handler__c>)platformCache.orgCache.get(
                TriggerHandlerCache.class, UTIL_PlatformCache.CacheBuilderStubParameter
            );
            duration = System.currentTimeMillis() - startTime;
        } else {
            duration = -1;
        }
    }

    private static List<Trigger_Handler__c> queryTriggerHandlerRecords() {
        return [SELECT Asynchronous__c, Class__c, Load_Order__c,
                Object__c, Active__c, Usernames_to_Exclude__c,
                Trigger_Action__c, User_Managed__c
            FROM Trigger_Handler__c
            ORDER BY Load_Order__c];
    }

    /**
     * @description Query Rollup__mdt using SOQL
     */
    private static void rollupCmdtSoql(){
        startTime = System.currentTimeMillis();
        Rollup__mdt[] results = queryRollupCmdtRecords();
        duration = System.currentTimeMillis() - startTime;
    }

    /**
     * @description Query Rollup__mdt using SOQL
     */
    private static void rollupCmdtCache(){
        startTime = System.currentTimeMillis();
        UTIL_PlatformCache platformCache = UTIL_PlatformCache.getInstance();
        if (platformCache.isOrgCacheAvailable) {
            Rollup__mdt[] results = (List<Rollup__mdt>)platformCache.orgCache.get(
                RollupMetadataCache.class, UTIL_PlatformCache.CacheBuilderStubParameter
            );
            duration = System.currentTimeMillis() - startTime;
        } else {
            duration = -1;
        }
    }

    private static List<Rollup__mdt> queryRollupCmdtRecords() {
        return [SELECT
                    Id,
                    DeveloperName,
                    MasterLabel,
                    Active__c,
                    Use_Fiscal_Year__c,
                    Description__c,
                    Operation__c,
                    Time_Bound_Operation_Type__c,
                    Integer__c,
                    Is_Deleted__c,
                    Filter_Group__c, Filter_Group__r.MasterLabel, Filter_Group__r.DeveloperName,
                    Summary_Object__r.QualifiedApiName, Summary_Object__r.Label,
                    Summary_Field__r.QualifiedApiName, Summary_Field__r.Label,
                    Detail_Object__r.QualifiedApiName, Detail_Object__r.Label,
                    Detail_Field__r.QualifiedApiName, Detail_Field__r.Label,
                    Amount_Object__r.QualifiedApiName, Amount_Object__r.Label,
                    Amount_Field__r.QualifiedApiName, Amount_Field__r.Label,
                    Date_Object__r.QualifiedApiName, Date_Object__r.Label,
                    Date_Field__r.QualifiedApiName, Date_Field__r.Label
                FROM Rollup__mdt
                WHERE Is_Deleted__c = false
                ORDER BY Summary_Object__c, MasterLabel
            ];
    }

    private static void describeTestA() {

        startTime = System.currentTimeMillis();

        String lbl = UTIL_Describe.getObjectLabel('Account');

        duration = System.currentTimeMillis() - startTime;
    }

    private static void describeTestB() {

        startTime = System.currentTimeMillis();

        String lbl = UTIL_Describe_LazyLoad.getObjectLabel('Opportunity');

        duration = System.currentTimeMillis() - startTime;
    }

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

    // ====================================================================
    // CACHEBUILDER CLASS TO MANAGE RETRIEVING/PUTTING ELEMENTS INTO THE CACHE
    // ====================================================================

    public class TriggerHandlerCache implements Cache.CacheBuilder {
        public List<Trigger_Handler__c> doLoad(String dummyParam) {
            List<Trigger_Handler__c> th = queryTriggerHandlerRecords();
            return th;
        }
    }

    public class RollupMetadataCache implements Cache.CacheBuilder {
        public List<Rollup__mdt> doLoad(String dummyParam) {
            List<Rollup__mdt> r = queryRollupCmdtRecords();
            return r;
        }
    }

}
