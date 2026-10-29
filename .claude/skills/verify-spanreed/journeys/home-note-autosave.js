// Home Note autosave: typing into a fresh run's empty Home Note writes Home.txt at once,
// as exact plain text with no smart quotes, smart dashes, or autocorrect.
// Precondition: a fresh run from `spanreed-verify launch` with no --home-text seed.
const typed = '"quoted" -- teh';

if (fs.readFileSync(homeNote, "utf8") !== "") throw new Error("precondition: Home.txt must start empty");
let before = await waitFor(/ID: note-editor/);
await snap("01-empty-home-note");

await act("click the Home Note editor", () => app.click(indexOf(before, /ID: note-editor/)));
await act(`type ${typed}`, () => app.typeText(typed));
await waitFor(/quoted.{0,2} -- teh/);
await waitForFile(homeNote, text => text === typed);
pass("Home.txt on disk holds exactly the typed text");
await snap("02-typed");
