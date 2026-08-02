// Sample.cpp — exercises Moped's C++ tokenizer.
#include <iostream>
#include <vector>
#include <string>

namespace sample {

class Shape {
public:
	virtual ~Shape() = default;
	virtual double area() const = 0;
};

class Circle : public Shape {
public:
	explicit Circle(double radius) : radius_(radius) {}
	double area() const override { return 3.14159265358979 * radius_ * radius_; }

private:
	double radius_;
};

} // namespace sample

int main() {
	std::vector<sample::Circle> circles = {sample::Circle(1.0), sample::Circle(2.5)};
	double total = 0.0;

	for (const auto &c : circles) {
		total += c.area();
	}

	std::cout << "Total area: " << total << std::endl;
	return 0;
}
