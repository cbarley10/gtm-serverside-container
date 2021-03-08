___TERMS_OF_SERVICE___

By creating or modifying this file you agree to Google Tag Manager's Community
Template Gallery Developer Terms of Service available at
https://developers.google.com/tag-manager/gallery-tos (or such other URL as
Google may provide), as modified from time to time.


___INFO___

{
  "type": "TAG",
  "id": "cvt_temp_public_id",
  "version": 1,
  "securityGroups": [],
  "displayName": "Klaviyo API Wrapper Template",
  "brand": {
    "id": "brand_dummy",
    "displayName": ""
  },
  "description": "Test For Il Makiage",
  "containerContexts": [
    "SERVER"
  ]
}


___TEMPLATE_PARAMETERS___

[
  {
    "type": "TEXT",
    "name": "public_key",
    "displayName": "Klaviyo Public API Key",
    "simpleValueType": true,
    "help": "Use your Public API Key from your Account Settings. More Info can be found here: https://help.klaviyo.com/hc/en-us/articles/115005062267-Manage-Your-Account-s-API-Keys#your-public-api-key-site-id2",
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ],
    "notSetText": "Public API Key cannot be blank!"
  }
]


___SANDBOXED_JS_FOR_SERVER___

//////////////
// Packages //
//////////////

const log = require("logToConsole");
const JSON = require("JSON");
const toBase64 = require('toBase64');
const fromBase64 = require('fromBase64');
const sendHttpRequest = require('sendHttpRequest');
const setResponseBody = require('setResponseBody');
const setResponseStatus = require('setResponseStatus');
const getAllEventData = require('getAllEventData');
const encodeUriComponent = require('encodeUriComponent');
const decodeUriComponent = require('decodeUriComponent');
const parseUrl = require('parseUrl');

///////////////
// Constants //
///////////////

// const testKEparam = "eyJrbF9lbWFpbCI6ICJjb25ub3J3YmFybGV5QGdtYWlsLmNvbSIsICJrbF9jb21wYW55X2lkIjogIlRwaDNQRCJ9";
const KL_PUBLIC_KEY = data.public_key;
const EVENT_DATA = getAllEventData();
log(EVENT_DATA);

/////////////
// Helpers //
/////////////

const encodePayload = payload => {
  const encodedPayload = encodeUriComponent(toBase64(JSON.stringify(payload)));
  return encodedPayload;
};

const decodePayload = input => {
  const decoded = JSON.parse(fromBase64(decodeUriComponent(input)));
  return decoded;
};

// .includes() isn't a method in this envrionment so use .indexOf()
const normalizeEventNames = name => {
  if (name === "add_to_cart") {
    return "Added To Cart";
  } else if (name === "view_item") {
    return "Viewed Product";
  } else if (name === "begin_checkout") {
    return "Started Checkout";
  } else if (name === "page_view"){
    return "Page Viewed";
  } else if (name.indexOf("_") > -1) {
    return name.split("_").map(item => item.charAt(0).toUpperCase() + item.slice(1)).join(" ");
  }
  return name.charAt(0).toUpperCase() + name.slice(1);
};

// Handle _ke and utm_email parameters
const containsKeOrUtmEmail = url => {
  const parsedUrl = parseUrl(url);
  if (parsedUrl.searchParams._ke){
    const email = decodePayload(parsedUrl.searchParams._ke).kl_email;
    return {
      "email": email
    };
  } else if (parsedUrl.searchParams.utm_email){
    const email = parsedUrl.searchParams.utm_email;
    return {
      "email": email
    };
  } else {
    return {
      email: ""
    };
  }
};

///////////////////
// API Functions //
///////////////////

const sendTrackRequest = payload => {
  const encodedPayload = encodePayload(payload);
  const url = "https://a.klaviyo.com/api/track?data=" + encodedPayload;
  return sendHttpRequest(url, (statusCode, headers, body) => {
    setResponseStatus(statusCode);
    setResponseBody(body);
   }, {headers: {user_agent: 'Klaviyo/GTM-Serverside'}, method: 'GET', timeout: 500});
};

const sendIdentifyRequest = payload => {
  const encodedPayload = encodePayload(payload);
  const url = "https://a.klaviyo.com/api/identify?data=" + encodedPayload;
  return sendHttpRequest(url, (statusCode, headers, body) => {
    setResponseStatus(statusCode);
    setResponseBody(body);
  }, {headers: {user_agent: 'Klaviyo/GTM-Test'}, method: 'GET', timeout: 500 });
};

///////////////
// Execution //
///////////////

log("starting script");

// if page_location contains _ke identify user and send Active On Site Metric
if(containsKeOrUtmEmail(EVENT_DATA.page_location).email && EVENT_DATA.event_name === "page_view"){
  log("-- KE or UTM_EMAIL PARAMETER DETECTED IN URL --");
  let email;
  if (containsKeOrUtmEmail(EVENT_DATA.page_location).email){
    email = containsKeOrUtmEmail(EVENT_DATA.page_location).email;
  }

  const identifyPayload = {
    "$email": email
  };
  const activeOnSitePayload = {
    "token": KL_PUBLIC_KEY,
    "event": "Page Viewed",
    "customer_properties": {
      "$email": email
    },
    "properties": EVENT_DATA
  };

  sendIdentifyRequest(identifyPayload);
  sendTrackRequest(activeOnSitePayload);
} else {
  log("=======================================================");
  log("No email found in URL. Not sending Klaviyo any data...");
  log("=======================================================");
}

if (EVENT_DATA["x-ga-mp2-user_properties"]) {
  if (EVENT_DATA["x-ga-mp2-user_properties"].email && EVENT_DATA["x-ga-mp2-user_properties"].id){
    const email = EVENT_DATA["x-ga-mp2-user_properties"].email;
    const id = EVENT_DATA["x-ga-mp2-user_properties"].id;
    log("Customer Email and ID found. Sending Klaviyo an event with $email: " + email + " and $id: " + id);
    const trackEventPayload = {
      "token": KL_PUBLIC_KEY,
      "event": EVENT_DATA.event_name,
      "customer_properties": {
        "$email": email,
        "$id": id
      },
      "properties": EVENT_DATA
    };
    sendTrackRequest(trackEventPayload);
  } else if (EVENT_DATA["x-ga-mp2-user_properties"].email && !EVENT_DATA["x-ga-mp2-user_properties"].id){
    const email = EVENT_DATA["x-ga-mp2-user_properties"].email;
    log("Customer Email found. Sending Klaviyo an event with $email: " + email);
    const trackEventPayload = {
      "token": KL_PUBLIC_KEY,
      "event": EVENT_DATA.event_name,
      "customer_properties": {
        "$email": email
      },
      "properties": EVENT_DATA
    };
    sendTrackRequest(trackEventPayload);
  } else if (!EVENT_DATA["x-ga-mp2-user_properties"].email && EVENT_DATA["x-ga-mp2-user_properties"].id) {
    const id = EVENT_DATA["x-ga-mp2-user_properties"].id;
    log("Customer ID found. Sending Klaviyo an event with $id: " + id);
    const trackEventPayload = {
      "token": KL_PUBLIC_KEY,
      "event": EVENT_DATA.event_name,
      "customer_properties": {
        "$id": id
      },
      "properties": EVENT_DATA
    };
    sendTrackRequest(trackEventPayload);
  } else {
    log("No customer ID or EMAIL found. Not sending Klaviyo any data...");
  }
}

log("ending script");
// Call data.gtmOnSuccess when the tag is finished.
data.gtmOnSuccess();


___SERVER_PERMISSIONS___

[
  {
    "instance": {
      "key": {
        "publicId": "logging",
        "versionId": "1"
      },
      "param": [
        {
          "key": "environments",
          "value": {
            "type": 1,
            "string": "debug"
          }
        }
      ]
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "send_http",
        "versionId": "1"
      },
      "param": [
        {
          "key": "allowedUrls",
          "value": {
            "type": 1,
            "string": "any"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "access_response",
        "versionId": "1"
      },
      "param": [
        {
          "key": "writeResponseAccess",
          "value": {
            "type": 1,
            "string": "any"
          }
        },
        {
          "key": "writeHeaderAccess",
          "value": {
            "type": 1,
            "string": "specific"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "read_event_data",
        "versionId": "1"
      },
      "param": [
        {
          "key": "eventDataAccess",
          "value": {
            "type": 1,
            "string": "any"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  }
]


___TESTS___

scenarios: []


___NOTES___

Created on 3/8/2021, 12:25:02 PM