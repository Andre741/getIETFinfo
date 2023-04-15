import fs from 'fs';
import { createObjectCsvWriter } from 'csv-writer';
import { count } from 'console';


const numberOutput = 2;

// Read each JSON file and parse the contents
const filenames = [
  'data/myIETFdata47to71.json',
  'data/myIETFdata72to79.json',
  'data/myIETFdata80to95.json',
  'data/myIETFdata96to96.json',
  'data/myIETFdata97to99.json',
  'data/myIETFdata100to108.json',
  'data/myIETFdata108to115.json'
];

const jsonObjects = filenames.map(file => JSON.parse(fs.readFileSync(file)));

// Merge the JSON objects into a single object
const mergedObject = Object.assign({}, ...jsonObjects);

// Convert the merged object to an array of records
let records = [];
Object.entries(mergedObject).forEach(([year, countries]) => {
  Object.entries(countries).forEach(([country, count]) => {
    records.push({ year, country, count, color: '#CCCCCC' });
  });
});



// remove entries where the country is undefined
records = records.filter(function (el) {
  const toBeFilteredOut = el.country != "undefined" && el.country != 'ISO 3166 Code';
  if (!toBeFilteredOut) {
    console.log("removed: " + el.year + " " + el.country + " " + el.count);
  }
  return toBeFilteredOut;
});

// an array with all countries in the EU
const EU = ["AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR", "DE", "GR", "HU", "IE", "IT", "LV", "LT", "LU", "MT", "NL", "PL", "PT", "RO", "SK", "SI", "ES", "SE", "GB"];

// an array with all countries in ASIA
const ASIA = ["AF", "AM", "AZ", "BH", "BD", "BT", "BN", "KH", "GE", "HK", "IN", "ID", "IR", "IQ", "IL", "JP", "JO", "KZ", "KW", "KG", "LA", "LB", "MO", "MY", "MV", "MN", "MM", "NP", "KP", "OM", "PK", "PH", "QA", "SA", "SG", "KR", "LK", "SY", "TW", "TJ", "TH", "TR", "TM", "AE", "UZ", "VN", "YE"];

// all the countries in the EU become EU, Asia becomes ASIA
records = records.map(function (el) {
  if (EU.includes(el.country)) {
    el.country = "EU";
  }
  if (ASIA.includes(el.country)) {
    el.country = "Asia";
  }
  switch (el.country) {
    case "EU": el.color = "#202A33"; break;
    case "US": el.color = "#F5E87F"; break;
    case "ASIA": el.color = "#B6A488"; break;
    case "CN": el.color = "#C2648E"; break;
  }
  // in the year the first part of the string 'meeting' is removed
  el.year = el.year.replace("meeting ", "");
  return el;
});

// Write the records to a CSV file
const csvWriterNormal = createObjectCsvWriter({
  path: `output/output${numberOutput}.csv`,
  header: [
    { id: 'year', title: 'Year' },
    { id: 'country', title: 'Country' },
    { id: 'count', title: 'Count' },
    { id: 'color', title: 'Color' }
  ]
});

// Write the records to a JSON file
const toPrint = JSON.stringify(records);
fs.writeFile(`output/myIETFdataCombined${numberOutput}.json`, toPrint, (err) => {
  if (err) throw err;
  console.log('Data written to file');
});

csvWriterNormal.writeRecords(records)
  .then(() => console.log('CSV file written successfully'))
  .catch(error => console.error('Error writing CSV file:', error));

// Spread the values
function reshapeData(data) {
  const reshapedData = {};

  data.forEach((item) => {
    const { year, country, count } = item;

    if (!reshapedData[year]) {
      reshapedData[year] = { Year: year };
    }
    // check if country already exists
    if (reshapedData[year][country]) {
      // if it exists, add the count to the existing value
      reshapedData[year][country] += count;
    } else {
      // if it doesn't exist, create a new entry
      reshapedData[year][country] = count;
    }
  });

  return Object.values(reshapedData);
}

let spreadData = reshapeData(records);
// create an array of all the countries only if once
let countries = [];
spreadData.forEach((item) => {
  Object.entries(item).forEach(([key, value]) => {
    if (key != "Year" && !countries.includes(key)) {
      countries.push(key);
    }
  });
});

let headersCountries = countries.map(function (el) {
  return { id: el, title: el };
});


// write the values to a different csv file, automatically with all the countries
const csvWriterReshaped = createObjectCsvWriter({
  path: `output/outputReshaped${numberOutput}.csv`,
  header: [
    { id: 'Year', title: 'Year' },
    ...headersCountries
  ]
});

csvWriterReshaped.writeRecords(spreadData)
  .then(() => console.log('CSV file Reshaped written successfully'))
  .catch(error => console.error('Error writing CSV file:', error));

