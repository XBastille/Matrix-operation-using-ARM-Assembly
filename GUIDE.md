# Guide for Matrix Calculator Project

This guide will walk you through creating a matrix calculator project in Keil µVision and getting it running on an LPC2148 microcontroller.

## Creating a New Project

1. Launch Keil µVision IDE
2. Click on **Project → New µVision Project**
3. Choose a location for your project and give it a name (e.g., "MatrixCalculator")
4. In the **Select Device for Target** dialog, navigate to:
   - **LPC2148**
5. Click **OK**

## Setting up the Project

1. In the **Select Software Components** dialog:
   - Expand **Device**
   - Check **Startup**
   - Click **OK**

2. You'll see your project in the Project Window with folders:
   - **Target 1**
      - **Source Group 1**
      - **Startup Code**

3. Right-click on **Source Group 1** and select **Add New Item to Group**
4. Select **Asm File** and name it matrix.asm
5. Copy the complete source code from the repository to this file

## Configuring Target Settings

1. Right-click on **Target 1** and select **Options for Target 'Target 1'**
2. On the **Target** tab:
   - Set **Xtal (MHz)** to `12.0`
   - Set **Memory Model** to match the LPC2148

3. On the **Output** tab:
   - Check **Create HEX File**

4. Click **OK** to save settings

## Building the Project

1. Click the **Build** button (F7) or select **Project → Build Target**
2. Wait for the compilation to complete
3. Check the **Build Output** window for any errors

## Testing the Calculator

1. After building successfully with no errors in build outputs, select **Start/stop Debug Session**

2. Click on **View → Serial Windows → UART #1**

3. Click the **Run** button (F5)

## Using the Matrix Calculator

1. You will see the prompt `Enter Matrix A (3x3):` in UART #1 window
2. Enter 9 integer values (one per prompt) for Matrix A
3. Next, you'll see `Enter Matrix B (3x3):`
4. Enter 9 integer values for Matrix B
5. When prompted `Enter operation (+, -, *):`, input one of:
   - `+` for addition
   - `-` for subtraction
   - `*` for multiplication
6. The calculator will display the result matrix

### Example Input/Output

```
Enter Matrix A (3x3):
Element [1,1]: 1
Element [1,2]: 2
Element [1,3]: 3
Element [2,1]: 4
Element [2,2]: 5
Element [2,3]: 6
Element [3,1]: 7
Element [3,2]: 8
Element [3,3]: 9

Enter Matrix B (3x3):
Element [1,1]: 9
Element [1,2]: 8
Element [1,3]: 7
Element [2,1]: 6
Element [2,2]: 5
Element [2,3]: 4
Element [3,1]: 3
Element [3,2]: 2
Element [3,3]: 1

Enter operation (+, -, *): +
Performing Addition:
Result Matrix:
10 10 10
10 10 10
10 10 10
```

## Troubleshooting

- If no text appears in the terminal:
  - Check your UART connection
  - Verify the baud rate (9600)
  - Ensure the program was flashed correctly

- If calculation results are incorrect:
  - Check if you entered the matrices correctly
  - Try using small test matrices with known results

For installation instructions, refer to [INSTALLATION.md](INSTALLATION.MD).
