/**
 * Class: Autocomplete Search
 * Description: Methods to search for records, meant to work with LWC autocompleteSearch
 * Author: Avodaas 2022
 */
public without sharing virtual class AutocompleteSearch {
    public static final Integer DEFAULT_SEARCH_RESULTS_LIMIT = 20;
    public static final String DEFAULT_RETURN_FIELD = 'Name';
    public static final Set<String> WIERD_FIELDS = new Set<String> {'Tier'};
    public static final Map<String,String> SOSL_RETURN_TYPE_MAP = new Map<String,String>{
        'NAME' => 'String',
        'EMAIL' => 'Email',
        'PHONE' => 'Phone'
    };

    public class AutoCompleteResult {
        @AuraEnabled
        public String Id { get;set; }
        @AuraEnabled
        public String value { get;set; }
    }
    
    @AuraEnabled
    public static List<AutoCompleteResult> getRecordsForAutocompleteSearch(String searchString, String searchField, String fieldsToReturn, String selectedSObject, Integer recordLimit, String fieldType, Map<String, Object> filterMap ) {
        if(String.isEmpty(searchString)) return new List<AutoCompleteResult>();
        if(recordLimit == null) recordLimit = DEFAULT_SEARCH_RESULTS_LIMIT;
        if(String.isNotBlank(fieldType)) return searchSObjectWithSOSL(selectedSObject, searchString, fieldType, recordLimit, filterMap );
        String whereClause = '';
        List<String> fieldsToSearach = searchField.split(',');
        Boolean firstRun = true;
        for(String singleSearchField : fieldsToSearach){
             //make sure we receive a valid sobject & field
            if(!ApxUtil.isSObjectAndfieldExists(selectedSObject, singleSearchField) || !ApxQL.isFieldQueryable(selectedSObject, singleSearchField)) return new List<AutoCompleteResult>();
            // at least try to prevent SOQL injection!!
            searchString = string.escapeSingleQuotes(searchString);
            if (firstRun) { firstRun = false; } else { whereClause += ' OR '; }
            whereClause += singleSearchField + ' LIKE \'%'+ searchString +'%\'';
        }
        String toWhereClause = '';
        System.debug('filterMap ' + filterMap);

        for (String fieldName: filterMap.keySet()) {
            String val = '' + filterMap.get(fieldName);
            if(val == null || String.isBlank(String.valueOf(val))) continue;
            toWhereClause = ApxUtil.toWhereClause(selectedSObject, fieldName, val);
            System.debug('filterMap ' + filterMap);
            if(string.isblank(toWhereClause)) continue;
            whereClause += ' AND ' + toWhereClause;
        }
        if(String.isBlank(whereClause)) return new List<AutoCompleteResult>();
        whereClause = ' ( ' + whereClause + ' ) ';
        System.debug('whereClause ' + whereClause);
        recordLimit = recordLimit == null ? DEFAULT_SEARCH_RESULTS_LIMIT : recordLimit;
        String rtClause = '';
        String returnFields = String.isBlank(fieldsToReturn) ? DEFAULT_RETURN_FIELD : string.escapeSingleQuotes(fieldsToReturn);
        String query = 'SELECT Id, ' + returnFields + ' FROM ' + selectedSObject + ' WHERE ' + whereClause + ' LIMIT ' + recordLimit;  
        try{
            AutoCompleteResult acr;
            List<SObject> sobjectList = Database.query(query);
            List<AutoCompleteResult> output = new List<AutoCompleteResult>();
            for(SObject sobj :sobjectList){
                acr = new AutoCompleteResult();
                acr.Id = String.valueOf(sobj.get('Id'));
                acr.value = getReturnValue(sobj, returnFields); 
                output.add(acr);
                }
            return output;
        } catch(Exception e){
            System.debug('Exception in getRecordsForAutocompleSearch. Query: ' + query + ' and the error: ' + e.getMessage() + ' ' + e.getStackTraceString());
            return new List<AutoCompleteResult>();
        }
    }

    public static String getReturnValue(SObject sobj, String returnFields) {
        if(String.isBlank(returnFields)) return String.valueOf(sobj.get(DEFAULT_RETURN_FIELD));
        String value = '';
        for(String field : returnFields.split(',')) value += String.valueOf(sobj.get(field.deleteWhitespace())) + ' ';
        return value.removeEnd(' ');
    }

    /*
    * searches (using SOSL) for a given Sobject type, this function can't sosl a Date field
    */
    public static List<AutoCompleteResult> searchSObjectWithSOSL(String selectedSObject, String searchString, String fieldType, Integer recordLimit, Map<String, Object> filterMap ){
        if(String.isBlank(selectedSObject) || String.isBlank(searchString) || searchString.length() < 3) return new List<AutoCompleteResult>();
        if(ApxUtil.isSObject(selectedSObject) == false) return new List<AutoCompleteResult>();
        String sfFieldType;
        if(SOSL_RETURN_TYPE_MAP.containsKey(fieldType.toUpperCase())) sfFieldType = SOSL_RETURN_TYPE_MAP.get(fieldType.toUpperCase());
        system.debug('selectedSObject'+selectedSObject+'sfFieldType'+sfFieldType);
        // get all field names by type on the selectedSObject
        List<String> searchFields = ApxUtil.getSObjectFieldsForObjectByType(selectedSObject, sfFieldType);
        system.debug('searchFields'+searchFields);
        if(searchFields.isEmpty()) return new List<AutoCompleteResult>();
       // for(String singleSearchField : searchFields)
        //make sure we receive a valid sobject & field
        //if(ApxQL.isFieldQueryable(selectedSObject, singleSearchField)) return new List<AutoCompleteResult>();
        Set<String> searchFieldsSet = new Set<String>(searchFields);
        for(String wField : WIERD_FIELDS){
            if(searchFieldsSet.contains(wField)) searchFieldsSet.remove(wField);
        }
        String fields = String.join(new List<String>(searchFieldsSet), ', ' );
        searchString = string.escapeSingleQuotes(searchString);
        // SOSL Search
        String searchStringForSOSL = '\'*' + searchString + '*\'';
        String rtClause = '';
        Set<String> values;
        String whereClause = '';
        String val = '';
        Boolean firstRun = true;
        String toWhereClause = '';
        for (String fieldName: filterMap.keySet()) {
            val = '' + filterMap.get(fieldName);
            if(val == null || String.isBlank(String.valueOf(val))) continue;
            toWhereClause = ApxUtil.toWhereClause(selectedSObject, fieldName, val);
            if(string.isblank(toWhereClause)) continue;
            if(firstRun){
                whereClause += ' WHERE';
                firstRun = false;
            } 
            else whereClause += ' AND ';
            whereClause += toWhereClause;
        }
        recordLimit = recordLimit == null ? DEFAULT_SEARCH_RESULTS_LIMIT : recordLimit;
        String soslQuery = 'FIND ' + searchStringForSOSL + ' IN ' + fieldType.toUpperCase() + ' FIELDS RETURNING '
                        + selectedSObject + ' (Id, ' + fields + whereClause + ') LIMIT ' + recordLimit ;
        System.debug('SOSL QUERY: ' + soslQuery);
        List<List<SObject>> results = Search.query(soslQuery);
        List<AutoCompleteResult> output = new List<AutoCompleteResult>();
        if(results.isEmpty()) return output;
        Map<String, Schema.SObjectField> sObjectFields = ApxUtil.getSObjectFields(selectedSObject);
        for(SObject sobj : results[0]){
            values = new Set<String>();
            for(String theField : searchFieldsSet){
                val = String.valueOf(sobj.get(theField));
                if(String.isBlank(val)) continue;
                if(val.toLowerCase().contains(searchString.toLowerCase())){
                    if(values.contains(val.toLowerCase())) continue;
                    AutoCompleteResult sr = new AutoCompleteResult();
                    sr.Id = (String)sobj.get('Id');
                    sr.value = val;
                    values.add(val.toLowerCase());
                    output.add(sr);
                }
            }
        }
        return output;
    }

}