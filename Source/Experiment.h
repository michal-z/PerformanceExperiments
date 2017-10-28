#pragma once

class Experiment
{
public:
	virtual void Initialize() = 0;
	virtual void Update(double frameTime, float frameDeltaTime) = 0;
	virtual void Draw() const = 0;
};
