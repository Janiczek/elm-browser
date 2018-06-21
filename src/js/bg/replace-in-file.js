const fs = require('async-file');
const {AsyncFileReader} = require('async-file-reader');

const doReplaceSingleLine = async (reader, from, to, replacement) => {

  const lineContent = await reader.readLine();
  const beginning = lineContent.slice(0, from.column);
  const end = lineContent.slice(to.column + 1);

  return beginning + replacement + end + "\n";

}

const doReplaceMultipleLines = async (reader, lineNum, from, to, replacement) => {

  let lineContent;

  if (lineNum === from.line) {

    lineContent = await reader.readLine();
    const beginning = lineContent.slice(0, from.column);
    return beginning + replacement;

  } else if (lineNum === to.line) {

    lineContent = await reader.readLine();
    const end = lineContent.slice(to.column + 1);
    return end + "\n";

  } else {

    // skip
    await reader.readLine();
    return "";

  }

};

const replaceInFile = async (filename, from, to, replacement) => {
  const reader = new AsyncFileReader(filename);

  let lineNum;
  let lineContent;
  let outputString = "";

  const replaceSingleLine = from.line === to.line;

  // before the lines: just copy
  for (lineNum = 0; lineNum < from.line; lineNum++) {
    lineContent = await reader.readLine();
    outputString += lineContent + "\n";
  }

  // the meat of the function. replace what you're supposed to replace
  for (lineNum = from.line; lineNum <= to.line; lineNum++) {
    outputString += await (replaceSingleLine
      ? doReplaceSingleLine(reader, from, to, replacement)
      : doReplaceMultipleLines(reader, lineNum, from, to, replacement));
  }

  // after the lines: just copy
  while ((lineContent = await reader.readLine()) != null) {
    outputString += lineContent + "\n";
  }

  // two more "\n" than we wanted :/
  outputString = outputString.slice(0, -1);

  await fs.writeFile(filename, outputString);
};

module.exports = replaceInFile;

//replaceInFile('test.txt', {line: 6, column: 15}, {line: 6, column: 17}, 'Hello, world!');
