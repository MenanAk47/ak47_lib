import { useState, useEffect } from 'react';

export const useInteractionListener = () => {
    const [bubbles, setBubbles] = useState({});

    useEffect(() => {
        const handleMessage = (event) => {
            const item = event.data;
            if (!item || !item.action) return;

            switch (item.action) {
                case 'display':
                    if (!item.id) return;
                    setBubbles(prev => ({
                        ...prev,
                        [item.id]: item
                    }));
                    break;

                case 'hide':
                    if (item.id) {
                        setBubbles(prev => {
                            const newBubbles = { ...prev };
                            delete newBubbles[item.id];
                            return newBubbles;
                        });
                    }
                    break;

                case 'hideAll':
                    setBubbles({});
                    break;

                default:
                    break;
            }
        };

        window.addEventListener('message', handleMessage);
        return () => window.removeEventListener('message', handleMessage);
    }, []);

    return bubbles;
};