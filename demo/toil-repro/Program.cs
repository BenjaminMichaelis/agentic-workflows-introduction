// Minimal, deliberately trivial "application" surface.
// The only reason this project exists is to reference a real, currently-known
// vulnerable NuGet package version so that `dotnet list package --vulnerable`
// reports a real finding (GHSA-5crp-9r3c-p9vr, Newtonsoft.Json < 13.0.1).
// The fix is a one-line version bump: 12.0.1 -> 13.0.1.
using Newtonsoft.Json;

var payload = new { message = "toil, not thinking" };
Console.WriteLine(JsonConvert.SerializeObject(payload));
