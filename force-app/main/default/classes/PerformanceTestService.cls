public inherited sharing class PerformanceTestService {

    /**
     * @description The API name of the org cache partition to use for testing. This specific partition is part of this repo/folder structure.
     */
    private static final String CACHE_PARTITION_NAME = 'testing';

    /**
     * queryTriggerHandlerRecords Retrieve the Trigger_Handler__c records via SOQL mimicing how it's handled in TDTM
     * @return   return List<Trigger_Handler__c>
     */
    public static List<Trigger_Handler__c> queryTriggerHandlerRecords() {
        return [SELECT Asynchronous__c, Class__c, Load_Order__c,
                Object__c, Active__c, Usernames_to_Exclude__c,
                Trigger_Action__c, User_Managed__c
            FROM Trigger_Handler__c
            ORDER BY Load_Order__c];
    }
    /**
     * queryTriggerHandlerRecords Retrieve the Rollup_mmdt records via SOQL mimicing how it's handled in CRLP
     * @return   return List<Rollup__mdt>
     */
    public static List<Rollup__mdt> queryRollupCmdtRecords() {
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

    /**
     * queryTriggerHandlerRecords Retrieve the Data_Import_Field_Mapping__mdt records via SOQL mimicing how it's handled in Gift Entry
     * @return   return List<Data_Import_Field_Mapping__mdt>
     */
    public static List<Data_Import_Field_Mapping__mdt> queryDataImportMappings() {
        return [SELECT
                    Id,
                    Label,
                    MasterLabel,
                    DeveloperName,
                    Data_Import_Field_Mapping_Set__c,
                    Data_Import_Field_Mapping_Set__r.Label,
                    Data_Import_Field_Mapping_Set__r.DeveloperName,
                    Required__c,
                    Source_Field_API_Name__c,
                    Target_Field_API_Name__c,
                    Target_Object_Mapping__c,
                    Target_Object_Mapping__r.Object_API_Name__c,
                    Target_Object_Mapping__r.DeveloperName,
                    Target_OBject_Mapping__r.Legacy_Data_Import_Object_Name__c,
                    Target_Object_Mapping__r.MasterLabel,
                    Is_Deleted__c
            FROM Data_Import_Field_Mapping__mdt
            WHERE Is_Deleted__c = false];
    }

    private static final String objectName = 'Opportunity';
    private static Map<Schema.SObjectType, Schema.DescribeSObjectResult> objectDescribesByType = new Map<Schema.SObjectType, Schema.DescribeSObjectResult>();

    /**
     * @description Describe using the default (full) behavior.
     * Simulates the behavior in UTIL_Describe by retrieving the Global Describe first!
     */
    public static Schema.DescribeSObjectResult getObjectDescribeFull() {
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        Schema.DescribeSObjectResult objDescribe = gd.get(objectName).getDescribe(SObjectDescribeOptions.Default);
        objectDescribesByType.put(objDescribe.getSObjectType(), objDescribe);
        return objDescribe;
    }

    /**
     * @description Describe using the recently releaed Deferred behavior.
     * Simulates the behavior in UTIL_Describe by retrieving the Global Describe first!
     */
    public static Schema.DescribeSObjectResult getObjectDescribeDeferred() {
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        Schema.DescribeSObjectResult objDescribe = gd.get(objectName).getDescribe(SObjectDescribeOptions.Deferred);
        objectDescribesByType.put(objDescribe.getSObjectType(), objDescribe);
        return objDescribe;
    }

    // ====================================================================
    // CACHE HANDLER CLASS TO RETRIEVE THE ORG CACHE PARTITION
    // ====================================================================

    public class CacheUtil {
        public Cache.OrgPartition orgCache;

        public CacheUtil() {
            this.orgCache = Cache.Org.getPartition(CACHE_PARTITION_NAME);
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
    public class DataImportMappingsCache implements Cache.CacheBuilder {
        public List<Data_Import_Field_Mapping__mdt> doLoad(String dummyParam) {
            List<Data_Import_Field_Mapping__mdt> r = queryDataImportMappings();
            return r;
        }
    }

}
