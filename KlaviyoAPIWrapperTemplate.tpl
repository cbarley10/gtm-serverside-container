//////////////
// Packages //
//////////////

const JSON = require("JSON");
const log = require("logToConsole");
const parseUrl = require('parseUrl');
const toBase64 = require('toBase64');
const sendHttpRequest = require('sendHttpRequest');
const setResponseBody = require('setResponseBody');
const getAllEventData = require('getAllEventData');
const setResponseStatus = require('setResponseStatus');
const encodeUriComponent = require('encodeUriComponent');

///////////////
// Constants //
///////////////

const KL_PUBLIC_KEY = data.public_key;
const EVENT_DATA = getAllEventData();
const HEADERS = {
  'user-agent': 'Klaviyo/GTM-Serverside',
  'Accept': 'text/html',
  'Content-Type': 'application/x-www-form-urlencoded'
};

/////////////
// Helpers //
/////////////

// Encode JSON payload to Base64 in order to send event to Klaviyo
const encodePayload = payload => encodeUriComponent(toBase64(JSON.stringify(payload)));

// Return only unique values in an array
const returnUniques = (value, index, self) => {
  return self.indexOf(value) === index;
};

// pull out nested fields in "items" array of the ecommerce object, and add them as top-level fields
const flatten = event => {
  const flattenedObj = event;
  const objectKeys = [];
  const ecommerceObjectItems = event.items;

  for(let property in ecommerceObjectItems[0]){
    objectKeys.push(property);
  }
  objectKeys.forEach(item => {
    flattenedObj[item] = ecommerceObjectItems.map(i => i[item]).filter(returnUniques);
  });

  return flattenedObj;
};


// Normalize event names so that they look better in Klaviyo and conform to Klaviyo naming convention
const normalizeEventNames = name => {
//  if (name === "add_to_cart") {
//    return "Added To Cart";
//  } else if (name === "view_item") {
//    return "Viewed Product";
//  } else if (name === "begin_checkout") {
//    return "Started Checkout";
//  } else if (name === "page_view"){
//    return "Page Viewed";
//  } else if (name.indexOf("_") > -1) {
//    return name.split("_").map(item => item.charAt(0).toUpperCase() + //item.slice(1)).join(" ");
//  }
//  return name.charAt(0).toUpperCase() + name.slice(1);
  return name;
};

// Build track payload
const buildPayload = (event, user) => {
  const customerProperties = {};
//  if (user.id) {
  log("User_id (buildPayload): "+user.id);
  customerProperties["$id"] = user.id;
//  }
//  if (user.email) {
//    customerProperties["$email"] = user.email;
//  }
//  if (user.exchange_id) {
//    customerProperties["$exchange_id"] = user.exchange_id;
//  }

  return {
    "token": KL_PUBLIC_KEY,
    "event": normalizeEventNames(eventName),
    "customer_properties": customerProperties,
    "properties": event.hasOwnProperty("items") ? flatten(EVENT_DATA) : EVENT_DATA
  };
};

// Handle _kx and utm_email parameters
const getUser = (url, eventData) => {
  const parsedUrl = parseUrl(url) || "";
  const userProperties = eventData || "";
//  const userProperties = eventData["x-ga-mp2-user_properties"] || "";
//  if (parsedUrl && parsedUrl.searchParams._kx){
//    const kx = parsedUrl.searchParams._kx;
//    return {
//      "email": "",
//      "id": "",
//      "exchange_id": kx
//    };
//  } else if (parsedUrl && parsedUrl.searchParams.utm_email){
//    const email = parsedUrl.searchParams.utm_email;
//    return {
//      "email": email,
//      "id": "",
//      "exchange_id": ""
//    };
//  } else if (userProperties && userProperties.user_data.user_id){
log("userProperties.user_id (getUser): "+userProperties.user_id);
  return {
//      "email": "",
      "id": userProperties.user_id,
//      "exchange_id": ""
    };
//  } else {
//    return {
//      "email": "",
//      "id": "",
//      "exchange_id": ""
//    };
//  }
};

///////////////////
// API Functions //
///////////////////

const sendTrackOrIdentifyRequest = (method, payload) => {
  const encodedPayload = encodePayload(payload);
  const url = "https://a.klaviyo.com/api/" + method + "?data=" + encodedPayload;
  log(url);
  return sendHttpRequest(url, (statusCode, headers, body) => {}, {headers: HEADERS, method: 'GET'});
};

///////////////
// Execution //
///////////////

log("==== STARTING SCRIPT ====");
//log(EVENT_DATA);
const user = getUser(EVENT_DATA.page_location, EVENT_DATA);
const eventName = EVENT_DATA.event_name;

// if page_location contains _kx identify user and send Active On Site Metric
//if (/*user.email || user.exchange_id ||*/ user.id && eventName === "page_view"){
//  log("_kx or utm_email were found. Tracking an event");
if(user.id) {
log("Tracking an event. "+user.id+", "+eventName);
  const payload = buildPayload(EVENT_DATA, user);
  sendTrackOrIdentifyRequest("track", payload);
//} else if (user.id && eventName !== "page_view") {
  // if event is not page view, get id and exchange_id and see if they exist
//  log("$id found. Tracking an event. "+user.id+", "+eventName);
//  const payload = buildPayload(EVENT_DATA, user);
//  sendTrackOrIdentifyRequest("track", payload);
} else {
//  log("No customer $exchange_id, $email, or $id found. Not sending Klaviyo any data...");
  log("No customer $id found. Not sending Klaviyo any data...");
}

log("==== ENDING SCRIPT ====");
// Call data.gtmOnSuccess when the tag is finished.
data.gtmOnSuccess();
