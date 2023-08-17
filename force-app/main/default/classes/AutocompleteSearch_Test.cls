/**
 *	AutocompleteSearch
 *	@description Unit tests for AutocompleteSearch class
 *	@date	Jul 2022
 */
@isTest
private class AutocompleteSearch_Test {
	@isTest static void AutocompleteSearch_Test() {
		Account acct = new Account(Name = 'Test');
		insert acct;

		Contact con = new Contact(LastName = 'Test', AccountId = acct.Id, phone = '345763457633');
		insert con;

		Id [] fixedSearchResults= new Id[1];
		Map<String, Object> filterMap = new Map<String, Object>();
		fixedSearchResults[0] = con.Id;
		Test.setFixedSearchResults(fixedSearchResults);
		List<AutocompleteSearch.AutoCompleteResult> sObjs = AutocompleteSearch.getRecordsForAutocompleteSearch('', 'Name', 'Contact', 10, null, null);
		sObjs = AutocompleteSearch.getRecordsForAutocompleteSearch('A Name', 'Bad Name', 'Contact', null, null, filterMap);
		sObjs = AutocompleteSearch.getRecordsForAutocompleteSearch('A Name', 'Name', 'Contact', null, null, filterMap);
		sObjs = AutocompleteSearch.getRecordsForAutocompleteSearch('A Name', 'Name', 'Contact', null, null, new Map<String, Object>{'LastName'=> 'Test'});
		sObjs = AutocompleteSearch.getRecordsForAutocompleteSearch('A Name', 'Bad Name', 'Contact', 10, null, filterMap);
		sObjs = AutocompleteSearch.getRecordsForAutocompleteSearch('Last Man 4', 'Name', 'Contact', 10, 'Caller', filterMap);
		sObjs = AutocompleteSearch.searchSObjectWithSOSL('Contact', '34576', 'Phone', 10, filterMap);
		filterMap.put('RecordTypeId', '0124x000000MfaKAAS');
		sObjs = AutocompleteSearch.searchSObjectWithSOSL('Contact', '34576', 'Phone', 10, filterMap);

		system.assertEquals(' Phone like \'%5555555555%\' ', ApxUtil.toWhereClause('Contact', 'Phone', '5555555555'));
		system.assertEquals(' LastName like \'TestLastName%\' ', ApxUtil.toWhereClause('Contact', 'LastName', 'TestLastName'));
		system.assertEquals(' (LastName like \'TestLastName%\' OR LastName like \'TestFirstName%\' ) ', ApxUtil.toWhereClause('Contact', 'LastName', 'TestLastName,TestFirstName'));
		system.assertEquals(' Type = \'Mechanical\' ', ApxUtil.toWhereClause('Case', 'Type', 'Mechanical'));
		system.assertEquals('  (Reason = \'Installation\' OR Reason = \'Performance\')', ApxUtil.toWhereClause('Case', 'Reason', 'Installation;Performance|'));
		system.assertEquals(' Id = \'000000000000000AAA\' ', ApxUtil.toWhereClause('Case', 'Id', '000000000000000AAA'));
		system.assertEquals(' Id in (000000000000000AAA,000000000000000AAB) ',ApxUtil.toWhereClause('Case', 'Id', '(000000000000000AAA,000000000000000AAB)'));
		system.assertEquals(' AccountId = \'000000000000000AAA\' ', ApxUtil.toWhereClause('Contact', 'AccountId', '000000000000000AAA'));
		system.assertEquals(' NumberOfEmployees >= 6  AND NumberOfEmployees <=  5 ' ,ApxUtil.toWhereClause('Account', 'NumberOfEmployees', '6 - 5'));
		system.assertEquals(' NumberOfEmployees <=  5 ' ,ApxUtil.toWhereClause('Account', 'NumberOfEmployees', '< 5'));
		system.assertEquals(' NumberOfEmployees >=  5 ' ,ApxUtil.toWhereClause('Account', 'NumberOfEmployees', '> 5'));
		system.assertEquals(' NumberOfEmployees = 5 ' ,ApxUtil.toWhereClause('Account', 'NumberOfEmployees', '5'));
		system.assertEquals(' IsConverted = false' ,ApxUtil.toWhereClause('Lead', 'IsConverted', 'No'));
		system.assertEquals(' Description like \'%some text%\' ', ApxUtil.toWhereClause('Case', 'Description', 'some text'));
	}
}