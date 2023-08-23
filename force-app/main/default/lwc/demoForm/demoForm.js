import { LightningElement, api, wire } from 'lwc';

import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

import CONTACT_OBJECT from '@salesforce/schema/Contact';
import CONTACT_NAME_FIELD from '@salesforce/schema/Contact.Name';
import CONTACT_ACCOUNT_FIELD from '@salesforce/schema/Contact.AccountId';
import CONTACT_ACCOUNT_NAME_FIELD from '@salesforce/schema/Contact.Account.Name';

import { getRecordTypeByName } from 'c/jsUtils';

const CONTACT_FIELDS = [CONTACT_NAME_FIELD, CONTACT_ACCOUNT_FIELD, CONTACT_ACCOUNT_NAME_FIELD];
const RESIDENT_RT_NAME = 'Resident';

export default class DemoForm extends LightningElement {

    @api recordId;

    residentId;
    selectedConName;
    conObjectInfo;
    residentRecordTypeId;
    selectedAcctName;
    acctId;
    phoneVal;

    @wire(getRecord, { recordId: '$recordId', fields: CONTACT_FIELDS })
    wiredResident({ error, data }) {
        if (data) {
            this.residentRecord = data;
            this.error = undefined;
            this.residentId = this.recordId;
            this.selectedConName = getFieldValue(data, CONTACT_NAME_FIELD);
            this.acctId = getFieldValue(data, CONTACT_ACCOUNT_FIELD);
            this.selectedAcctName = getFieldValue(data, CONTACT_ACCOUNT_NAME_FIELD);
        } else if (error) {
            this.error = error;
            this.residentRecord = undefined;
        }
    }

    @wire(getObjectInfo, { objectApiName: CONTACT_OBJECT })
    setResidentRT({ data, error }) {
        if(data) {
            this.conObjectInfo = data;
            this.residentRecordTypeId = getRecordTypeByName(this.conObjectInfo.recordTypeInfos, RESIDENT_RT_NAME);
        }
        else if(error) console.log('the error: ', error);
    }

    get residentFilter() {
        return { 'RecordTypeId' : this.residentRecordTypeId };
    }

    handleConChange(event) {
        this.residentId = event.detail.Id;
    }

    clearExistingCon() {
        this.residentId = null;
    }

    handleAcctChange(event) {
        this.acctId = event.detail.value;
    }

    clearExistingAcct() {
        this.acctId = null;
    }

    handlePhoneChange(event) {
        phoneVal = event.detail.value;
    }

    clearExistingPhone() {
        phoneVal = null;
    }

}