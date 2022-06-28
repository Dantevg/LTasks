module DateFormats

import StdEnv
import iTasks

import iTasks.Extensions.DateTime
import Data.Functor
from Data.List import elemIndex

Start :: *World -> *World
Start world = doTasks dateTask world

:: DateAsNamedMonth =
	{ year  :: !Int
	, mon   :: !String
	, day   :: !Int
	}

:: DateFormat
	= AsString !String
	| AsNumeric !Date
	| AsNamedMonth !DateAsNamedMonth

derive JSONEncode   DateAsNamedMonth, DateFormat
derive JSONDecode   DateAsNamedMonth, DateFormat
derive gEq          DateAsNamedMonth, DateFormat
derive gText        DateAsNamedMonth, DateFormat
derive gEditor      DateAsNamedMonth, DateFormat
derive gHash        DateAsNamedMonth, DateFormat

months = ["jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec"]

toMonth :: String -> ? Int
toMonth monthName = (\x -> x + 1) <$> (elemIndex monthName months)

dateString :: Task DateFormat
dateString = updateInformation [] "" <<@ Hint "date as string:"
	@ AsString

dateNumeric :: Task DateFormat
dateNumeric = enterInformation [] <<@ Hint "date as numeric:"
	@ AsNumeric

dateNamedMonth :: Task DateFormat
dateNamedMonth = enterInformation [] <<@ Hint "date as named-month:"
	@ AsNamedMonth

toDate :: DateFormat -> ? Date
toDate (AsString date) = error2mb (parseDate date)
toDate (AsNumeric date) = ?Just date
toDate (AsNamedMonth {DateAsNamedMonth|year,mon,day}) = case toMonth mon of
	?Just monthInt = ?Just {Date|year=year, mon=monthInt, day=day}
	?None = ?None
toDate _ = ?None

tvToDate :: (TaskValue DateFormat) -> ? (Task Date)
tvToDate (Value date _) = case toDate date of
	?Just date = ?Just (return date)
	?None = ?None
tvToDate (NoValue) = ?None

dateTask = anyTask [dateString, dateNumeric, dateNamedMonth]
	>>* [OnAction ActionContinue tvToDate]
	>>- (\date -> viewInformation [] date)