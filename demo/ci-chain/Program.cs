using CsvHelper;
using CsvHelper.Configuration;
using System.Globalization;

var configuration = new CsvConfiguration(CultureInfo.InvariantCulture);
configuration.HasHeaderRecord = false;

using var writer = new StringWriter();
using var csv = new CsvWriter(writer, configuration);
csv.WriteField("demo");
csv.NextRecord();
Console.Write(writer.ToString());