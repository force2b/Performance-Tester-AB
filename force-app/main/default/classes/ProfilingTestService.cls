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
public inherited sharing class ProfilingTestService {

    /**
     * @description The API name of the org cache partition to use for testing. This specific partition is part of this repo/folder structure.
     */
    private static final String CACHE_PARTITION_NAME = 'testing';

    /**
     * queryTriggerHandlerRecords Retrieve the Trigger_Handler__c records via SOQL mimicing how it's handled in TDTM
     * @return  List<Trigger_Handler__c>
     */
    public static List<Trigger_Handler__c> queryTriggerHandlerRecords() {
        return [SELECT Asynchronous__c, Class__c, Load_Order__c,
                Object__c, Active__c, Usernames_to_Exclude__c,
                Trigger_Action__c, User_Managed__c
            FROM Trigger_Handler__c
            ORDER BY Load_Order__c];
    }
    /**
     * queryRollupCmdtRecords Retrieve the Rollup_mmdt records via SOQL mimicing how it's handled in CRLP
     * @return  List<Rollup__mdt>
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
     * queryDataImportMappings Retrieve the Data_Import_Field_Mapping__mdt records via SOQL mimicing how it's handled in Gift Entry
     * @return  List<Data_Import_Field_Mapping__mdt>
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

    // Objects to describe
    private static final List<String> objects =  new List<String> {
        'Opportunity', 'Contact', 'Account'
    };
    private static Map<Schema.SObjectType, Schema.DescribeSObjectResult> objectDescribesByType = new Map<Schema.SObjectType, Schema.DescribeSObjectResult>();

    /**
     * @description Describe using the default (full) behavior.
     * Simulates the behavior in UTIL_Describe by retrieving the Global Describe first!
     */
    public static void getObjectDescribeFull() {
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        for (String obj: objects) {
            Schema.DescribeSObjectResult objDescribe = gd.get(obj).getDescribe(SObjectDescribeOptions.Default);
            objectDescribesByType.put(objDescribe.getSObjectType(), objDescribe);
        }
    }

    /**
     * @description Describe using the recently releaed Deferred behavior.
     * Simulates the behavior in UTIL_Describe by retrieving the Global Describe first!
     */
    public static void getObjectDescribeDeferred() {
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        for (String obj: objects) {
            Schema.DescribeSObjectResult objDescribe = gd.get(obj).getDescribe(SObjectDescribeOptions.Deferred);
            objectDescribesByType.put(objDescribe.getSObjectType(), objDescribe);
        }
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
