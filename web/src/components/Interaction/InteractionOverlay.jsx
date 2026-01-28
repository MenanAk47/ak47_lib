import React from 'react';
import { useInteractionListener } from '../../hooks/useInteractionListener';
import Bubble from './Bubble';
import './Interaction.css';

const InteractionOverlay = () => {
    const bubbles = useInteractionListener();

    return (
        <div className="interaction-layer">
            {Object.values(bubbles).map(bubbleData => (
                <Bubble key={bubbleData.id} data={bubbleData} />
            ))}
        </div>
    );
};

export default InteractionOverlay;