import React from 'react';
import InteractionOverlay from './components/Interaction/InteractionOverlay';
import ProgressBar from './components/Progress/ProgressBar';

function App() {
  return (
    <div className="App">
      <InteractionOverlay />
      <ProgressBar />
      <div style={{ position: 'absolute', bottom: 20, right: 20, color: 'white', opacity: 0.5 }}>
        React HUD Loaded
      </div>
    </div>
  );
}

export default App;