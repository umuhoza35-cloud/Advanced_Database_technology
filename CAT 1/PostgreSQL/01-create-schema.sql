CREATE TABLE Officer (
    OfficerID INT PRIMARY KEY,
    FullName VARCHAR(100) NOT NULL,
    Station VARCHAR(100),
    BadgeNo VARCHAR(20) UNIQUE NOT NULL,
    Contact VARCHAR(15)
);

CREATE TABLE Driver (
    DriverID INT PRIMARY KEY,
    FullName VARCHAR(100) NOT NULL,
    LicenseNo VARCHAR(20) UNIQUE NOT NULL,
    Contact VARCHAR(15),
    City VARCHAR(50)
);
CREATE TABLE Vehicle (
    VehicleID INT PRIMARY KEY,
    DriverID INT NOT NULL,
    PlateNo VARCHAR(20) UNIQUE NOT NULL,
    Type VARCHAR(50),
    Status VARCHAR(20) DEFAULT 'Active',
    FOREIGN KEY (DriverID) REFERENCES Driver(DriverID)
);
CREATE TABLE Violation (
    ViolationID INT PRIMARY KEY,
    VehicleID INT NOT NULL,
    OfficerID INT NOT NULL,
    Date DATE NOT NULL,
    Type VARCHAR(100),
    Penalty DECIMAL(10,2),
    FOREIGN KEY (VehicleID) REFERENCES Vehicle(VehicleID),
    FOREIGN KEY (OfficerID) REFERENCES Officer(OfficerID)
);
CREATE TABLE Fine (
    FineID INT PRIMARY KEY,
    ViolationID INT NOT NULL,
    Amount DECIMAL(10,2) NOT NULL,
    Status VARCHAR(20) DEFAULT 'Unpaid',
    DueDate DATE,
    FOREIGN KEY (ViolationID) REFERENCES Violation(ViolationID)
);
CREATE TABLE Payment (
    PaymentID INT PRIMARY KEY,
    FineID INT NOT NULL,
    Amount DECIMAL(10,2) NOT NULL,
    PaymentDate DATE NOT NULL,
    Method VARCHAR(30),
    FOREIGN KEY (FineID) REFERENCES Fine(FineID)
);
