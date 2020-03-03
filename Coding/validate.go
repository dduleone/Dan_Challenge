package main

import (
	"bufio"
	"fmt"
	"os"
	"regexp"
	"strconv"
	"strings"
)

/*
 1. Open file for reading.
 2. Read first line of input.
 3. Validate first line of input
 4. Read ${input_lines[0]} number of additional lines
 5. For each line print either "Valid" or "Invalid"
*/

const IS_VALID = "Valid"
const IS_INVALID = "Invalid"

var readFirstLine = false

// const INPUT_FILE = "sample.txt"
const INPUT_FILE = "input.txt"

// Explicitly an int64, because that's what strconv.ParseInt() returns.
var numberOfCcNumbersToRead int64 = 0

func isValidCreditCardNumber(ccNum string) string {
	// Check it starts with 4, 5 or 6
	if !regexp.MustCompile(`^[456]`).MatchString(ccNum) {
		return IS_INVALID
	}

	// Check that the number is exactly 16 digits
	//    I thought about checking that the string is exactly either 16 or 19 characters.
	//    But that seemed like overkill, and not explicitly in the instructions.
	if countMatches(ccNum, `\d`) != 16 {
		return IS_INVALID
	}

	// Check for any characters other than digits or hyphens.
	if countMatches(ccNum, `[^\d-]`) != 0 {
		return IS_INVALID
	}

	// If there are hyphens, they must be distributed 0000-0000-0000-0000.
	if countMatches(ccNum, `-`) != 0 {
		if countMatches(ccNum, `^\d{4}-\d{4}-\d{4}-\d{4}$`) != 1 {
			return IS_INVALID
		}
	}

	// Test if any number is repeated 4 times.
	//    [Note]: Some people might call this more explicit or expressive:
	//            `0{4}|1{4}|2{4}|3{4}|4{4}|5{4}|6{4}|7{4}|8{4}|9{4}`
	//        It's the same number of characters. ¯\_(ツ)_/¯
	//        But if Go supported backreferences, this is so much nicer:
	//            getMatchesAsString(ccNum, `\d`), `(\d)\1{3}`)
	if countMatches(getMatchesAsString(ccNum, `\d`), `0000|1111|2222|3333|4444|5555|6666|7777|8888|9999`) != 0 {
		return IS_INVALID
	}

	// If we made it this far, the number is presumed valid.
	return IS_VALID
}

func getMatches(haystack, needleRegex string) [][]int {
	patternToMatch := regexp.MustCompile(needleRegex)
	return patternToMatch.FindAllStringIndex(haystack, -1)
}

func countMatches(haystack, needleRegex string) int {
	return len(getMatches(haystack, needleRegex))
}

func getMatchesAsString(haystack, needleRegex string) string {
	patternToMatch := regexp.MustCompile(needleRegex)
	matches := patternToMatch.FindAllString(haystack, -1)
	return strings.Join(matches[:], "")
}

func main() {
	file, _ := os.Open(INPUT_FILE)

	fscanner := bufio.NewScanner(file)
	for fscanner.Scan() {
		// Get line of text
		line := fscanner.Text()

		// Check if we've read the first line of the file.
		if !readFirstLine {
			// We haven't read the first line, yet. So we need to read it to know how many more lines to read.
			if number, err := strconv.ParseInt(line, 10, 64); err == nil {
				// Detect non-numeric characters in the first line of the input file
				if !regexp.MustCompile(`^\d+$`).MatchString(line) {
					fmt.Println("ERROR! Detected non-numeric characters in rowcount on first line of input file.")
					os.Exit(-1)
				}

				// We successfully parsed our integer, so gear up the engine and let's go.
				numberOfCcNumbersToRead = number
				readFirstLine = true

				// The problem explicitly states N must be 0 < N < 100
				if numberOfCcNumbersToRead <= 0 || numberOfCcNumbersToRead >= 100 {
					fmt.Println("ERROR! Rowcount on first line of input file must be between 0 and 100!")
					os.Exit(-1)
				}
			} else {
				// If strconv.ParseInt resulted in an error, we have an invalid first line.
				fmt.Println("ERROR! Invalid rowcount on first line of input file.")
				os.Exit(-1)
			}
		} else {

			// There are no instructions regarding what to do if there are too many lines in the file,
			//    so exit once we've read the number of lines specified on the first line.
			//
			//    #CS101Trap
			if numberOfCcNumbersToRead <= 0 {
				os.Exit(0)
			}

			// Reduce the number of lines left to read
			numberOfCcNumbersToRead--

			// We should read this next line and report if it's a valid credit card number.
			fmt.Println(isValidCreditCardNumber(line))
		}
	}

	// End
	return
}
