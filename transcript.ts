const fs = require('fs');
const csv = require('csv-parser');

type CsvLine = {
    'Start time': string;
    'End time': string;
    Channel: string;
    Transcript: string;
};


type CSVtranscript = CsvLine[];

type SpeakerLines = {
    [speaker: string]: {
        startTime: number;
        endTime: number;
        transcript: string;
    }[];
};

const inputFilePath = 'rawData/1.csv';
const outputFilePath = 'rawData/1.vtt';

const speakerLines: SpeakerLines = {};

const readCSV = async (path: string): Promise<CSVtranscript> => {
    const results: any[] = [];
    return new Promise((resolve, reject) => {
        fs.createReadStream(path)
            .pipe(csv())
            .on('data', (data) => results.push(data))
            .on('error', (error) => reject(error))
            .on('end', () => resolve(results));
    });
};

function formatTime(time: number): string {
    const seconds = Math.floor(time % 60).toString().padStart(2, '0');
    const minutes = Math.floor((time / 60) % 60).toString().padStart(2, '0');
    const hours = Math.floor(time / 3600).toString().padStart(2, '0');
    return `${hours}:${minutes}:${seconds}.000`;
}

function convertWebVtt(csvLines: CSVtranscript): string[] {
    const speakerLines: SpeakerLines = {};
    for (const line of csvLines) {
        const { 'Start time': startTime, 'End time': endTime, Channel: speaker, Transcript: transcript } = line;
        if (!speakerLines[speaker]) {
            speakerLines[speaker] = [];
        }
        speakerLines[speaker].push({ startTime: parseFloat(startTime), endTime: parseFloat(endTime), transcript });
    }
    const output: string[] = [''];
    for (const speaker in speakerLines) {
        for (const { startTime, endTime, transcript } of speakerLines[speaker]) {
            const startTimeFormatted = formatTime(startTime);
            const endTimeFormatted = formatTime(endTime);
            const speakerTag = `<v ${speaker}>`;
            const speakerTranscript = `${speakerTag}${transcript}`;
            output.push(`${startTimeFormatted} --> ${endTimeFormatted}`, speakerTranscript, '');
        }
    }
    return output;
}

function saveWebVttFile(output: string[]): void {
    const outputStream = fs.createWriteStream(outputFilePath);
    for (const line of output) {
      outputStream.write(`${line}\n`);
    }
    outputStream.end();
  }

readCSV(inputFilePath).then((data) => {
    const webVttLines = convertWebVtt(data);
    console.log(webVttLines);
    saveWebVttFile(webVttLines);
});