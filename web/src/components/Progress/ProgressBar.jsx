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
                    const pct = Math.min((elapsed / item.duration) * 100, 100);
                    
                    setProgress(pct);

                    if (pct < 100) {
                        frameRef.current = requestAnimationFrame(animate);
                    } else {
                        setTimeout(() => {
                            setVisible(false);
                            fetch(`https://${GetParentResourceName()}/ProgressFinish`, {
                                method: 'POST',
                                body: JSON.stringify({})
                            }).catch(() => {}); 
                            setTimeout(() => {
                                setProgress(0);
                            }, 500);
                        }, 200);
                    }
                };
                cancelAnimationFrame(frameRef.current);
                frameRef.current = requestAnimationFrame(animate);
            } else if (item.command === 'cancel') {
                cancelAnimationFrame(frameRef.current);
                setVisible(false);
                setTimeout(() => {
                    setProgress(0);
                }, 500);
            }
        };

        window.addEventListener('message', handleMessage);
        return () => {
            window.removeEventListener('message', handleMessage);
            cancelAnimationFrame(frameRef.current);
        };
    }, []);

    const renderCapsule = () => (
        <div className="style-capsule">
            <div className="progress-header">
                {/* Left Side: Label */}
                <span>{data.label}</span>
                {/* Right Side: Percentage */}
                <span>{Math.floor(progress)}%</span>
            </div>
            <div className="bar-background">
                <div className="bar-fill" style={{ width: `${progress}%` }}></div>
            </div>
        </div>
    );

    const renderMinimal = () => (
        <div className="style-minimal">
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
            <div className="style-segments">
                <div className="segment-label">{data.label}</div>
                <div className="segment-row">
                    {[...Array(totalSegments)].map((_, i) => (
                        <div 
                            key={i} 
                            className={`segment ${i < filledSegments ? 'filled' : ''}`}
                        ></div>
                    ))}
                </div>
            </div>
        );
    };

    return (
        <div className={`progress-container ${visible ? 'show' : ''}`}>
            {data.type === 'capsule' && renderCapsule()}
            {data.type === 'minimal' && renderMinimal()}
            {data.type === 'segments' && renderSegments()}
        </div>
    );
};

export default ProgressBar;