import React, { useState, useEffect, useRef } from 'react';
import './ProgressBar.css';

const ProgressBar = () => {
    const [visible, setVisible] = useState(false);
    const [progress, setProgress] = useState(0);
    const [data, setData] = useState({
        label: 'Action',
        duration: 5000,
        type: 'capsule'
    });

    const frameRef = useRef();
    const startTimeRef = useRef();
    const circumference = 283; // 2 * PI * r (r=45)

    useEffect(() => {
        const handleMessage = (event) => {
            const item = event.data;
            if (!item || item.action !== 'progressbar') return;

            if (item.command === 'start') {
                setData({
                    label: item.label || 'Processing',
                    duration: item.duration || 3000,
                    type: item.type || 'capsule'
                });
                setProgress(0);
                setVisible(true);
                startTimeRef.current = Date.now();
                
                const animate = () => {
                    const now = Date.now();
                    const elapsed = now - startTimeRef.current;
                    const pct = Math.min((elapsed / (item.duration || 3000)) * 100, 100);
                    
                    setProgress(pct);

                    if (pct < 100) {
                        frameRef.current = requestAnimationFrame(animate);
                    } else {
                        setTimeout(() => {
                            setVisible(false);
                            if (window.GetParentResourceName) {
                                fetch(`https://${window.GetParentResourceName()}/ProgressFinish`, {
                                    method: 'POST',
                                    body: JSON.stringify({})
                                }).catch(() => {}); 
                            }
                            setTimeout(() => setProgress(0), 500);
                        }, 200);
                    }
                };
                cancelAnimationFrame(frameRef.current);
                frameRef.current = requestAnimationFrame(animate);
            } else if (item.command === 'cancel') {
                cancelAnimationFrame(frameRef.current);
                setVisible(false);
                setTimeout(() => setProgress(0), 500);
            }
        };

        window.addEventListener('message', handleMessage);
        return () => {
            window.removeEventListener('message', handleMessage);
            cancelAnimationFrame(frameRef.current);
        };
    }, []);

    // --- RENDERERS ---

    const renderRadialSmooth = () => {
        const offset = circumference - (progress / 100) * circumference;
        return (
            <div className="style-radial-circular">
                <div className="radial-wrapper">
                    <svg viewBox="0 0 100 100">
                        <circle cx="50" cy="50" r="45" className="track" />
                        <circle cx="50" cy="50" r="45" className="fill" 
                            style={{ strokeDashoffset: offset, strokeDasharray: circumference, strokeWidth: 4 }} 
                        />
                    </svg>
                    <div className="radial-label">{Math.floor(progress)}</div>
                </div>
                <div className="bottom-label">{data.label}</div>
            </div>
        );
    };

    const renderRadialOrbit = () => {
        const offset = circumference - (progress / 100) * circumference;
        return (
            <div className="style-radial-circular">
                <div className="radial-wrapper">
                    <svg viewBox="0 0 100 100">
                        <circle cx="50" cy="50" r="45" className="track" />
                        <circle cx="50" cy="50" r="45" className="fill" 
                            style={{ strokeDashoffset: offset, strokeDasharray: circumference }} 
                        />
                    </svg>

                    <div className="radial-label">{Math.floor(progress)}</div>

                    <div className="orbit-dot-container" style={{ transform: `rotate(${progress * 3.6}deg)` }}>
                        <div className="orbit-dot"></div>
                    </div>
                </div>
                <div className="bottom-label">{data.label}</div>
            </div>
        );
    };

    const renderRadialTicks = () => {
        const totalTicks = 12;
        const filledTicks = Math.floor((progress / 100) * totalTicks);
        return (
            <div className="style-radial-circular">
                <div className="ticks-container">
                    {[...Array(totalTicks)].map((_, i) => (
                        <div 
                            key={i} 
                            className={`radial-tick ${i < filledTicks ? 'filled' : ''}`}
                            style={{ transform: `rotate(${i * 30}deg)` }}
                        />
                    ))}
                </div>
            </div>
        );
    };

    const renderRadialDashed = () => {
        const offset = circumference - (progress / 100) * circumference;
        return (
            <div className="style-radial-circular">
                <div className="radial-wrapper">
                    <svg viewBox="0 0 100 100">
                        <defs>
                            <mask id="dash-mask">
                                <circle cx="50" cy="50" r="45" stroke="white" strokeWidth="4" strokeDasharray="2 6" fill="none" />
                            </mask>
                        </defs>
                        <circle cx="50" cy="50" r="45" className="track-dashed" />
                        <circle cx="50" cy="50" r="45" className="fill-dashed" 
                            mask="url(#dash-mask)"
                            style={{ strokeDashoffset: offset, strokeDasharray: circumference }} 
                        />
                    </svg>
                    <div className="dashed-center">
                        <span className="dashed-title">{data.label}</span>
                        <span className="dashed-value">{Math.floor(progress)}</span>
                    </div>
                </div>
            </div>
        );
    };

    const renderCapsule = () => (
        <div className="style-linear-upward style-capsule">
            <div className="progress-header">
                <span>{data.label}</span>
                <span>{Math.floor(progress)}%</span>
            </div>
            <div className="bar-background">
                <div className="bar-fill" style={{ width: `${progress}%` }}></div>
            </div>
        </div>
    );

    const renderMinimal = () => (
        <div className="style-linear-upward style-minimal">
            <div className="progress-title">{data.label}</div>
            <div className="line-background">
                <div className="line-fill" style={{ width: `${progress}%` }}></div>
            </div>
            <div className="progress-footer">
                <span>Progress</span>
                <span>{Math.floor(progress)}%</span>
            </div>
        </div>
    );

    const renderSegments = () => {
        const totalSegments = 8;
        const filledSegments = Math.floor((progress / 100) * totalSegments);
        return (
            <div className="style-linear-upward style-segments">
                <div className="segment-label">{data.label}</div>
                <div className="segment-row">
                    {[...Array(totalSegments)].map((_, i) => (
                        <div key={i} className={`segment ${i < filledSegments ? 'filled' : ''}`}></div>
                    ))}
                </div>
            </div>
        );
    };

    const renderPulse = () => (
        <div className="style-linear-upward style-pulse">
            <div className="pulse-wrapper">
                <div className="pulse-dot"></div>
                <div className="pulse-dot"></div>
                <div className="pulse-dot"></div>
            </div>
            <div className="pulse-label">{data.label}</div>
        </div>
    );

    return (
        <div className={`progress-container ${visible ? 'show' : ''} type-${data.type}`}>
            {data.type === 'capsule' && renderCapsule()}
            {data.type === 'minimal' && renderMinimal()}
            {data.type === 'segments' && renderSegments()}
            {data.type === 'pulse' && renderPulse()}
            {data.type === 'radial-smooth' && renderRadialSmooth()}
            {data.type === 'radial-orbit' && renderRadialOrbit()}
            {data.type === 'radial-ticks' && renderRadialTicks()}
            {data.type === 'radial-dashed' && renderRadialDashed()}
        </div>
    );
};

export default ProgressBar;