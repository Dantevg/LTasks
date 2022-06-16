    {
        type = typed.Schema("DateTableNumeric")
            :field("year", "number")
            :field("month", "number")
            :field("day", "number"),
        action = "continue",
        fn = function(date)
            return task.constant(date)
        end
    },
    {
        type = typed.Schema("DateTableNamed")
            :field("year", "number")
            :field("month", "string")
            :field("day", "number"),
        action = "continue",
        fn = function(date)
            date.month = validMonths[date.month]
            return task.constant(date)
        end
    },
} ~ {{fn = function(date)
    return editor.viewInformation(app.pretty(date))
end}}