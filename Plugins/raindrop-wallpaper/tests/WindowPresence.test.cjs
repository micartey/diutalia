const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");

const context = vm.createContext({});
vm.runInContext(fs.readFileSync(path.join(__dirname, "../WindowPresence.js"), "utf8").replace(/^\.pragma library\s*/, ""), context);
const outputs = (...args) => JSON.parse(JSON.stringify(context.occupiedOutputs(...args)));
const event = (state, value) => JSON.parse(JSON.stringify(context.applyNiriEvent(state, value)));

const workspaces = [
  { id: 1, output: "DP-1", isActive: true },
  { id: 2, output: "DP-1", isActive: false },
  { id: 3, output: "DP-2", isActive: true }
];
assert.deepEqual(outputs(workspaces, [], false), {});
assert.deepEqual(outputs(workspaces, [{ workspaceId: 2 }], false), {});
assert.deepEqual(outputs(workspaces, [{ workspaceId: 1 }, { workspaceId: 2 }], false), { "DP-1": true });
assert.deepEqual(outputs(workspaces, [{ workspaceId: 1 }, { workspaceId: 3 }], false), { "DP-1": true, "DP-2": true });
assert.deepEqual(outputs(workspaces, [{ workspaceId: 1, handle: { minimized: true } }], false), {});
assert.deepEqual(outputs(workspaces, [{ workspaceId: 1, toplevel: { minimized: true } }], false), {});
assert.deepEqual(outputs(workspaces, [{ workspaceId: 99 }], false), {});
assert.deepEqual(outputs(workspaces, [{ workspaceId: 1, output: "DP-2" }], true), { "DP-2": true });
assert.deepEqual(outputs(workspaces, [{ workspaceId: 1 }], true), {});

const state = { workspaces: [], windows: [] };
assert.deepEqual(event(state, { WorkspacesChanged: { workspaces: [
  { id: 1, output: "DP-1", is_active: true },
  { id: 2, output: "DP-1", is_active: false },
  { id: 3, output: "DP-2", is_active: true }
] } }), {});
assert.deepEqual(event(state, { WindowsChanged: { windows: [
  { id: 10, workspace_id: 1 }, { id: 11, workspace_id: 3 }
] } }), { "DP-1": true, "DP-2": true });
assert.deepEqual(event(state, { WorkspaceActivated: { id: 2, focused: true } }), { "DP-2": true });
assert.deepEqual(event(state, { WindowOpenedOrChanged: { window: { id: 10, workspace_id: 2 } } }), { "DP-1": true, "DP-2": true });
assert.equal(state.windows.length, 2);
assert.deepEqual(event(state, { WindowClosed: { id: 11 } }), { "DP-1": true });
assert.deepEqual(event(state, { WindowOpenedOrChanged: { window: { id: 10, workspace_id: null } } }), {});
assert.equal(event(state, { WindowFocusChanged: { id: 10 } }), null);
assert.deepEqual(event(state, { WindowsChanged: { windows: [] } }), {});
assert.deepEqual(event(state, { WorkspacesChanged: { workspaces: [] } }), {});
console.log("Window presence tests passed");
