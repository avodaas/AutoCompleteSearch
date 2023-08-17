import { ShowToastEvent } from 'lightning/platformShowToastEvent';

//general useful definitions
const SUCCESS = 'success';
const ERROR = 'error';
const WARNING = 'warn';

//getting a date in string format and returning a js date
//returns the current dat if no val param
function getDateFormat(val) {
    let date = !val ? new Date() : new Date(val);
    let dd = String(date.getDate()).padStart(2, '0');
    let mm = String(date.getMonth() + 1).padStart(2, '0');
    let yyyy = date.getFullYear();
    return yyyy + '-' + mm + '-' + dd;
}

/**
 * @description: Display toast message
 * @name showToastMessage
 * @params The LWC object, String title for message, String message, String variant
 *          Legal values: SUCCESS, ERROR
 * @returns: none
 * */
function showToastMessage(lwc, title, message, variant){
    lwc.dispatchEvent(
        new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        })
    );
}

/**
 * @description: checks if all the html elements of a specific type on the page are valid.
 * @name formValid
 * @params The LWC object, the html elemnt
 * @returns: Boolean 
 * */
function formValid(lwc, elementType){
return [...lwc.template.querySelectorAll(elementType)]
        .reduce((validSoFar, inputField) => {
            inputField.reportValidity();
            return (validSoFar && inputField.checkValidity());
        }, true);
}

function getRecordTypeByName(recordTypes, rtName){
    return Object.keys(recordTypes).find(rti => recordTypes[rti].name === rtName);
}

function setUpAppointment(resident, facilityVisitId, status, followUp){
    let fields = {
        'sobjectType': 	'Appointment__c',
        'Resident__c': resident,
        'Facility_Visit__c': facilityVisitId,
        'Status__c': status,
        'From_Follow_Up__c': followUp
    }
    return fields;
}
function getLWCName(lwc){
    return lwc.template.host.localName // c-test-component
        .split('-')              // ['c', 'test', 'component'] 
        .slice(1)                // removes ns prefix => ['test', 'component']
        .reduce((a, b) => a + b.charAt(0).toUpperCase() + b.slice(1)); // converts to camelCase => testComponent 
}


async function flushPromises() {
    return Promise.resolve();
}


export {SUCCESS, ERROR, WARNING, showToastMessage, flushPromises, getDateFormat, formValid, getRecordTypeByName, setUpAppointment, getLWCName};