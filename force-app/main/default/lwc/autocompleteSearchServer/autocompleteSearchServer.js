import { LightningElement, api} from 'lwc';  
import getRecordsForAutocompleteSearch from '@salesforce/apex/AutocompleteSearch.getRecordsForAutocompleteSearch';

export default class AutocompleteSearchServer extends LightningElement {

	@api searchString = '';
	@api selectedName;
	@api selectedsobject;  
	@api recordLimit = 20;  
	@api searchLabel;  
	@api searchField;
	@api fieldsToReturn;
	@api searchDisabled = false;
	@api fieldType;
	@api isRequired;
	@api objectjson = Object.assign({},{});
	@api hardCodedOptions;

	noRecordsFlag = false;
	showoptions = false;

	@api
	loadRecords(){
		if(!this.searchString) return;
		this.noRecordsFlag = 0;  
		if(this.hardCodedOptions){
			//filter the options that were sent to the lwc based on the name.
			return this.populateRecords(this.hardCodedOptions.filter(rec => rec.value?.toLowerCase().includes(this.searchString.toLowerCase())));
		}
		// Wire method to function, which accepts the Search String, Dynamic SObject, Record Limit, Search Field  
		getRecordsForAutocompleteSearch({searchString: this.searchString , selectedSObject : this.selectedsobject, recordLimit : this.recordLimit, 
			searchField : this.searchField, fieldsToReturn: this.fieldsToReturn, fieldType :this.fieldType, filterMap: this.objectjson})
		.then(result => {
			this.populateRecords(result);
		})
		.catch(error => {
			this.error = error;  
			this.records = undefined;  
			this.showoptions = false;
		});
	}

	populateRecords(recs){
		this.records = this.combineRecordValues(recs);
		this.error = undefined;  
		this.noRecordsFlag = this.records.length === 0 ? true : false;  
		this.showoptions = !this.noRecordsFlag;
	}

	// handle event called lookupselect  
	handlelookupselect(event){
		this.selectedName = event.detail.value;
		this.showoptions = false;  
	}  
	// key change on the text field  
	handleKeyChange(event) {
		if(this.searchString != event.target.value){
			this.searchString = event.target.value;
			setTimeout(() => {
				this.loadRecords();
			}, 500);
		} 
	}
	// every time input changes including clicking x
	inputChanged(event) {
		if(this.searchDisabled) {
			let searchEle = this.template.querySelector('[data-id="search-input"]');
			if(searchEle) searchEle.value = this.selectedName;
			return;
		}
		this.selectedName = event.detail.value;
		if(this.selectedName == '') this.handleClear();
		if(!this.noRecordsFlag){
			const changedEvent = new CustomEvent('inputchanged');
			this.dispatchEvent(changedEvent);
		}
	}
	@api handleClear(){
		this.searchString = '';
		this.selectedName = '';
		this.records = [];
		const changedEvent = new CustomEvent('unlookupselect');
		this.dispatchEvent(changedEvent);
	}
	combineRecordValues(data){
		let recordMap = new Map();
		data.forEach(rec =>{
			let curRec ={};
			if(recordMap.has(rec.Id)){
				curRec.Id = recordMap.get(rec.Id).Id;
				curRec.value = recordMap.get(rec.Id).value + ', ' + rec.value;
			}else curRec = rec;
			recordMap.set(rec.Id, curRec);
		});
		return Array.from(recordMap.values());
	}
}