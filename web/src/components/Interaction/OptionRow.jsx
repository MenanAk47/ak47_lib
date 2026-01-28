import React, { useEffect, useRef } from 'react';
import { BOX_SIZE, PERIMETER } from '../../constants/interaction';

const OptionRow = ({ opt, id, index }) => {
    const keyBoxRef = useRef(null);

    // Calculate progress ring
    const progress = opt.progress || 0;
    const dashOffset = PERIMETER - (progress * PERIMETER);

    // Handle "bump" animation when key is pressed/active
    useEffect(() => {
        if (opt.activeBump && keyBoxRef.current) {
            keyBoxRef.current.classList.remove('bump');
            void keyBoxRef.current.offsetWidth; // Trigger reflow to restart animation
            keyBoxRef.current.classList.add('bump');
        }
    }, [opt.activeBump]);

    return (
        <div className="option-row">
            <div 
                ref={keyBoxRef}
                className={`key-box ${opt.hold > 0 ? 'is-hold' : ''}`}
                id={`key-box-${id}-${index}`}
            >
                {opt.hold > 0 && (
                    <svg 
                        className="progress-svg" 
                        width={BOX_SIZE} 
                        height={BOX_SIZE} 
                        viewBox={`0 0 ${BOX_SIZE} ${BOX_SIZE}`}
                    >
                        <path 
                            d="M 16 1 L 27 1 A 4 4 0 0 1 31 5 L 31 27 A 4 4 0 0 1 27 31 L 5 31 A 4 4 0 0 1 1 27 L 1 5 A 4 4 0 0 1 5 1 Z"
                            className="progress-path"
                            style={{ 
                                strokeDasharray: PERIMETER, 
                                strokeDashoffset: dashOffset 
                            }}
                        />
                    </svg>
                )}
                <span className="key-text">{opt.key}</span>
            </div>
            <div className="action-label">{opt.text}</div>
        </div>
    );
};

export default OptionRow;