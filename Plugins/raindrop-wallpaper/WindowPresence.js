.pragma library

function occupiedOutputs(workspaces, windows, globalWorkspaces) {
  const outputs = {};
  for (const window of windows) {
    if (window.toplevel?.minimized || window.handle?.minimized)
      continue;
    for (const workspace of workspaces) {
      if (!workspace.isActive || workspace.id !== window.workspaceId)
        continue;
      // Stacking backends share workspaces; use each window's actual output.
      const output = globalWorkspaces ? window.output : workspace.output;
      if (output)
        outputs[output] = true;
    }
  }
  return outputs;
}

function applyNiriEvent(state, event) {
  if (event.WorkspacesChanged) {
    state.workspaces = event.WorkspacesChanged.workspaces;
  } else if (event.WorkspaceActivated) {
    const active = state.workspaces.find(ws => ws.id === event.WorkspaceActivated.id);
    if (active) {
      for (const workspace of state.workspaces) {
        if (workspace.output === active.output)
          workspace.is_active = workspace.id === active.id;
      }
    }
  } else if (event.WindowsChanged) {
    state.windows = event.WindowsChanged.windows;
  } else if (event.WindowOpenedOrChanged) {
    const window = event.WindowOpenedOrChanged.window;
    state.windows = state.windows.filter(existing => existing.id !== window.id);
    state.windows.push(window);
  } else if (event.WindowClosed) {
    state.windows = state.windows.filter(window => window.id !== event.WindowClosed.id);
  } else {
    return null;
  }
  return occupiedOutputs(
    state.workspaces.map(ws => ({ id: ws.id, output: ws.output, isActive: ws.is_active })),
    state.windows.map(window => ({ workspaceId: window.workspace_id })),
    false
  );
}
