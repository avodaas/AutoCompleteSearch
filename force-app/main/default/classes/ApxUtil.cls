public with sharing class ApxUtil {


    /**
    * @description 
    * gets an object name and a field type and returns all the fields on the object that their type = field type
    **/
    public static List<String> getSObjectFieldsForObjectByType(String objName, String fieldType){
        List<String> fields = new List<String>();
        SObjectType sobjType = Schema.getGlobalDescribe().get(objName);
        Schema.DescribeSObjectResult dfrLkp = sobjType.getDescribe();
        for(schema.SObjectField sotype : dfrLkp.fields.getMap().values()){
            Schema.DescribeFieldResult fieldDescObj = sotype.getDescribe();
            if(fieldDescObj.getType().name() == fieldType){
                fields.add(fieldDescObj.getName()); // api field name
            }
        }
        return fields;
    }

    /***
     * @description Get a map of sobject field API Names to the actual SObjectField object
     * @param String object api name
     * @return Map of field api names & SObjectField objects
     */
    public static Map<String, Schema.SObjectField> getSObjectFields(String objectAPIName){
        Schema.DescribeSObjectResult describeResult = getSObjectDescribeResult(objectAPIName);
        if(describeResult == null) return null;
        Map<String, Schema.SObjectField> fields = new Map<String, Schema.SObjectField>();
        Map<String, Schema.SObjectField> objFields = describeResult.fields.getMap();
        Schema.DescribeFieldResult dfr;
        for(Schema.SObjectField field: objFields.values()){
            dfr = field.getDescribe();
            fields.put(dfr.getName(), field);
        }
        return fields;
    }

    public static final Map<String, Schema.DescribeSObjectResult> cachedGlobalDsrs{
        get {
            if (cachedGlobalDsrs == null) {
                cachedGlobalDsrs = new Map<String,Schema.DescribeSObjectResult>();
                List<Schema.DescribeSObjectResult> objects = Schema.describeSObjects(New List<String>(cachedGlobalDescribe.keySet()));
                for(Schema.DescribeSObjectResult sdSoj : objects) cachedGlobalDsrs.put(sdSoj.getName(), sdSoj);
            }
            return cachedGlobalDsrs;
        } private set;
    }

    /**
     * @description Get Describe Sobject Result
     * @param String object api name
     * @return Describe SObject result or null if it doesn't exist
     */
    public static Schema.DescribeSObjectResult getSObjectDescribeResult(String objectAPIName){
        try{
            if(cachedGlobalDsrs.containsKey(objectAPIName)) return cachedGlobalDsrs.get(objectAPIName);
            else return null;
        } catch(System.InvalidParameterValueException e){
            //object doesn't exist
            return null;
        }
    }

    public static final Map<String, Schema.SObjectType> cachedGlobalDescribe{
        get{
            if(cachedGlobalDescribe == null){
                 cachedGlobalDescribe = Schema.getGlobalDescribe();
            }
            return cachedGlobalDescribe;
        } private set;
    }

    /**
     * Check if SObject by given name exists in org
     * https://gist.github.com/nigamgoyal/b5ec5e3dc5350182c938792a20401683
     */
    public static Boolean isSObject(String objectNameParam){
        for (Schema.SObjectType sObjectType : cachedGlobalDescribe.values()) {
           String sobjName = String.valueOf(sObjectType);
           if (sobjName.equalsIgnoreCase(objectNameParam)) return true;
        }
        return false;
    }

    /**
    * Check if field by given name exists on given SObject
    */
    public static Boolean isSObjectAndfieldExists(String sObjectName, String fieldName){
        if(!isSObject(sObjectName)) return false;
        //special case
        if(fieldName == 'Name') return true;
        try{
            if(!cachedGlobalDescribe.containsKey(SObjectName)) return false;
            Schema.DescribeSObjectResult objResult = getSObjectDescribeResult(SObjectName);
            if(objResult == null) return false;
            return objResult.fields.getMap().keySet().contains(fieldName.toLowerCase());
        }catch(Exception e){
            return false;
        }
    }

    // DisplayType Enum: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_enum_Schema_DisplayType.htm
    /**
     *	@description Translates a SObject field into the string version of the SOQL where clause
     *	@param json - Coming from lightning, like: $A.util.json.encode(component.get("v.contact")) or JSON.stringify(vcontact)
     *	@return Ex:  " IsActive = false "  |  " MultiSelect__c includes ('Option1','Option2') "
     */
    public static String toWhereClause(String sObjectName, String fieldName, Object value) {
        // Get the field map for the sobjectType (Ex: 'Contact')
        Map<String, Schema.SObjectField> fieldMap = cachedGlobalDsrs.containsKey(sObjectName) ? cachedGlobalDsrs.get(sObjectName).fields.getMap() : null;
        if(fieldMap == null) return ' ';
        String whereClause = ' ';
       
        String val = String.escapeSingleQuotes('' + value);  // Converting object to String
        if(fieldName == 'RecordType.Name') whereClause = fieldName + ' = \'' + val + '\''; //make sure the objet really has record Types
        
        if (fieldName != 'sobjectType' && fieldMap.get(fieldName) != null) {
            //Get data types for the fieldName, and build whereClause based on the field type
            Schema.DisplayType fieldDataType = fieldMap.get(fieldName).getDescribe().getType();
           
            if(fieldDataType == Schema.DisplayType.Boolean) {
                if (val == 'Yes') val = 'true';
                if (val == 'No') val = 'false';
                whereClause += fieldName + ' = ' + val;

            } else if(fieldDataType == Schema.DisplayType.Picklist) {
                if(!val.contains(';')) whereClause += fieldName + ' = \'' + val + '\' ';
                else {
                    List<String> eachOption = val.substringBeforeLast('|').split(';');
                    whereClause += ' (';
                    for (String option : eachOption) {
                        whereClause += fieldName + ' = \'' + option + '\' OR ';
                    }
                    whereClause = whereClause.removeEnd(' OR ') + ')';
                }
            } else if(fieldDataType == Schema.DisplayType.MultiPicklist) {
                String operator = val.substringAfterLast('|');		// Operator AND or OR saved as the last value in the multipicklists
                String values = val.substringBeforeLast('|');
                if (operator == null || String.isBlank(operator) || operator == 'OR') {
                    List<String> eachOption = val.substringBeforeLast('|').split(';');
                    whereClause += fieldName + ' includes (';
                    for (String option : eachOption) {
                        whereClause += '\'' + option + '\',';
                    }
                    whereClause = whereClause.removeEnd(',');
                    whereClause += ') ';
                } else if (operator == 'AND') {
                    String options = val.substringBeforeLast('|');
                    whereClause += fieldName + ' includes (\'' + options + '\') ';		// This was an exact match => //fieldName + ' = \'' + options + '\' ';
                }

            } else if(fieldDataType == Schema.DisplayType.Date) {
                // TODO
            } else if(fieldDataType == Schema.DisplayType.DateTime) {
                // TODO
            } else if(fieldDataType == Schema.DisplayType.Double || fieldDataType == Schema.DisplayType.CURRENCY || fieldDataType == Schema.DisplayType.INTEGER) {
                // Allowing for number ranges!
                if (val.contains('-')) {
                    String numBefore = val.substringBefore('-');
                    String numAfter = val.substringAfter('-');
                    whereClause += fieldName + ' >= ' + numBefore + ' AND ' + fieldName + ' <= ' + numAfter + ' ';
                } else if (val.contains('<')) {
                    String num = val.substringAfter('<');
                    whereClause += fieldName + ' <= ' + num + ' ';
                } else if (val.contains('>')) {
                    String num = val.substringAfter('>');
                    whereClause += fieldName + ' >= ' + num + ' ';
                } else {
                    whereClause += fieldName + ' = ' + val + ' ';
                }
            } else if(fieldDataType == Schema.DisplayType.ID) {
                if (val.startsWith('(')) {
                    // We have a list of ids.  Search across all these ids
                    System.debug('  val before escaping: ' + val);
                    System.debug('  val AFTER escaping: ' + String.escapeSingleQuotes(val));
                    whereClause += fieldName + ' in ' + val.remove('\\') + ' ';
                } else {
                    whereClause += fieldName + ' = \'' + val + '\' ';
                }
            } else if(fieldDataType == Schema.DisplayType.Phone) {
                String last4digits = val.substringAfterLast('-');
                whereClause += fieldName + ' like \'%' + ((String.isEmpty(last4digits)) ? val : last4digits) + '%\' ';
            } else if(fieldDataType == Schema.DisplayType.Reference) {
                whereClause += fieldName + ' = \'' + val + '\' ';
            } else if(fieldDataType == Schema.DisplayType.String || fieldDataType == Schema.DisplayType.EMAIL) {
                if (val.contains(';') && val.contains('|')) {
                    // Has format (like on Doctor_Category__c coming from the Doctor RSP) 'PSY;SW|OR'  
                    //   - This is usually for picklists, but here we want to convert to regular string search
                    val = val.replaceAll(';', ',').substringBeforeLast('|');
                }
                if (val.contains(',')) {
                    whereClause += '(';
                    List<String> vals = val.split(',');
                    for (String searchText : vals) {
                        whereClause += fieldName + ' like \'' + searchText.trim() + '%\' OR ';
                    }
                    whereClause = whereClause.removeEnd('OR ') + ') ';
                } else {
                    whereClause += fieldName + ' like \'' + val + '%\' ';	// Only want wild card on last part  ///' like \'%' + val + '%\' ';
                }
            } else if(fieldDataType == Schema.DisplayType.TextArea) {
                whereClause += fieldName + ' like \'%' + val + '%\' ';
            } else if(fieldDataType == Schema.DisplayType.Time) {
                // TODO
            } else if(fieldDataType == Schema.DisplayType.URL) {
                // TODO
            }
        }

        return whereClause;
    }
}