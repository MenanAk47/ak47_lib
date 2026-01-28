import React, { useState, useEffect } from 'react';
import OptionRow from './OptionRow';

const Bubble = ({ data }) => {
    const { id, x, y, scale, options, mode, arc } = data;
    const [isVisible, setIsVisible] = useState(false);

    // Trigger enter animation
    useEffect(() => {
        requestAnimationFrame(() => setIsVisible(true));
    }, []);

    const style = {
        left: `${x * 100}vw`,
        top: `${y * 100}vh`,
        '--target-scale': scale !== undefined ? scale : 1.0,
    };

    const containerClass = `interaction-container ${isVisible ? 'show' : ''} ${mode === 'mini' ? 'mode-mini' : ''}`;

    return (
        <div className={containerClass} style={style} id={`bubble-${id}`}>
            <div className="bubble-dot"></div>
            
            <div className="options-list">
                {options.map((opt, index) => (
                    <OptionRow 
                        key={`${id}-opt-${index}-${opt.key}`} 
                        opt={opt} 
                        id={id} 
                        index={index} 
                    />
                ))}
            </div>

            {arc && <div className="arc-line" style={{ display: 'block' }}></div>}
        </div>
    );
};

export default Bubble;