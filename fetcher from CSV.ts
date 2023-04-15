
const fs = require('fs');
const csv = require('csv-parser');

type SingleMeeting = {
  [key: string]: number; // { 'gb': 100 }
};

type MeetingStats = {
  [key: string]: SingleMeeting; // key is the country name
};

type CSV = {
  [key: string]: string; // { 'ISO Code': 'gb' }
};

let results: MeetingStats = {};

const start = 47;
const end = 71;

console.log("Fetching data from CSV");

const readCsv = async (path: string): Promise<CSV[]> => {
  const results: any[] = [];
  return new Promise((resolve, reject) => {
    fs.createReadStream(path)
      .pipe(csv())
      .on('data', (data) => results.push(data))
      .on('error', (error) => reject(error))
      .on('end', () => resolve(results));
  });
};

// get data from CSV file and convert it to JSON, returns SingleMeeting
const readData = async (path: string): Promise<SingleMeeting> => {
  const readData = await readCsv(path).then((data) => {
    return count(data);
  });
  return readData;
};

const count = (table: CSV[]): SingleMeeting => {
  let countries = {};
  for (let entry of table) {
    // could be any of c('ISO Country', 'ISO Country Code', 'ISO Code', 'ISO 3166 Code')
    let country = entry["ISO 3166 Code"] ?? entry["ISO"] ?? entry["ISO Code"] ?? entry["ISO Country Code"] ?? entry["ISO Country"];
    // make country in capital letters
    country = country?.toUpperCase();
    // group the countries and count participants
    if (country in countries) {
      countries[country] += 1;
    }
    else {
      countries[country] = 1;
    }
  }
  return countries;
}

const promises: Promise<void>[] = [];

// iterate over the CSVs
for (let i = start; i <= end; i++) {
  const promise = readData(`./output/${i}.csv`).then((data) => {
    console.log(`Data from ${i} fetched`);
    results["meeting " + i] = data;
  });
  promises.push(promise);
}

// Wait for all promises to resolve
Promise.all(promises).then(() => {
  console.log("All promises resolved.");
  writeToFile(results);
});

const writeToFile = (data: MeetingStats) => {
  const toPrint = JSON.stringify(data);

  fs.writeFile(`data/XmyIETFdata${start}to${end}.json`, toPrint, (err) => {
    if (err) throw err;
    console.log('Data written to file');
  });
}


