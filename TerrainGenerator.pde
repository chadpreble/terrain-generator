import controlP5.*;
ControlP5 cp;

ArrayList<PVector> points;
ArrayList<Integer> triangles;

Camera cam;

float positionX, positionY, positionZ;

float radius = 50;
float phi = 90;
float theta = 115;

Slider sRows;
Textfield tfLoad;

void setup() {
  size(1200, 800, P3D);

  cp = new ControlP5(this);

  sRows = cp.addSlider("numRows", 1, 100);

  Slider sCols = cp.addSlider("numCols", 1, 100);
  sCols.setPosition(10, 30).setCaptionLabel("Columns");

  Slider sSize = cp.addSlider("gridSize", 20, 50);
  sSize.setPosition(10, 50).setCaptionLabel("Terrain Size");

  Button bGenerate = cp.addButton("generate");
  bGenerate.setPosition(10, 70);

  tfLoad = cp.addTextfield("loadedFile").setCaptionLabel("Load From File");
  tfLoad.setPosition(10, 100).setValue("terrain0").setAutoClear(false);

  Toggle tStroke = cp.addToggle("strokeOn");
  tStroke.setPosition(250, 10).setCaptionLabel("Stroke");

  Toggle tColor = cp.addToggle("colorOn");
  tColor.setPosition(300, 10).setCaptionLabel("Color");

  Toggle tBlend = cp.addToggle("blendOn");
  tBlend.setPosition(350, 10).setCaptionLabel("Blend");

  Slider sHeightMod = cp.addSlider("heightMod", -5, 5);
  sHeightMod.setPosition(250, 50).setCaptionLabel("Height Modifier");

  Slider sSnowThreshold = cp.addSlider("snowThreshold", 1, 5);
  sSnowThreshold.setPosition(250, 70).setCaptionLabel("Snow Threshold");


  points = new ArrayList<PVector>();
  triangles = new ArrayList<Integer>();
  cam = new Camera();
}

int numRows = 10;
int numCols = 10;
float gridSize = 30;
boolean generate = false;
String loadedFile;
boolean strokeOn = true;
boolean colorOn = false;
boolean blendOn = false;
float heightMod = 1;
float snowThreshold = 5;

// Colors
color snow = color(255);
color rock = color(135, 135, 135);
color grass = color(143, 170, 64);
color dirt = color(160, 128, 84);
color water = color(0, 75, 200);

void draw() {
  perspective(radians(90.0f), width/(float)height, 0.1, 1000);
  cam.Update();
  background(0);


  // Stroke On/Off
  if (strokeOn) {
    stroke(0);
  } else {
    noStroke();
  }

  // Generate Terrain
  if (generate || (keyPressed && keyCode == ENTER)) {
    generateTerrain();
  }

  // Draw triangles to the screen
  rotate(X);
  beginShape(TRIANGLES);
  for (int i = 0; i < triangles.size(); i++) {
    int vertIndex = triangles.get(i);
    if (vertIndex == points.size()) {
      System.out.println(i);
    }
    PVector vert = points.get(vertIndex);
    if (colorOn) {
      setColor(vertIndex);
    }
    else{
      fill(255);
    }
    vertex(vert.x * -1, vert.y * heightMod, vert.z);
  }
  endShape();



  perspective();
  camera();
  sRows.setPosition(10, 10).setCaptionLabel("Rows");
}


class Camera {
  void Update() {

    positionX = radius * cos(radians(phi)) * sin(radians(theta));
    positionY = radius * cos(radians(theta));
    positionZ = radius * sin(radians(theta)) * sin(radians(phi));

    camera(positionX, positionY, positionZ, 0, 0, 0, 0, 1, 0);
  }
}

void generateTerrain() {

  points.clear();
  triangles.clear();


  // Add all vertices to ArrayList of PVectors
  float rowSize = gridSize / numRows;
  float colSize = gridSize / numCols;

  for (float x = -1 * gridSize / 2; x <= gridSize / 2 + 0.01f; x += rowSize) {
    for (float z = -1 * gridSize / 2; z <= gridSize / 2 + 0.01f; z += colSize) {
      points.add(new PVector(x, 0, z));
    }
  }

  // Set all triangle indexes
  int numVerts = numCols + 1;
  for (int curRow = 0; curRow < numRows; curRow++) {
    for (int startIndex = curRow * numVerts; startIndex < curRow * numVerts + numCols; startIndex++) {
      triangles.add(startIndex);
      triangles.add(startIndex + 1);
      triangles.add(startIndex + numVerts);
      triangles.add(startIndex + 1);
      triangles.add(startIndex + numVerts + 1);
      triangles.add(startIndex + numVerts);
    }
  }

  // Set height for vertices
  if (loadImage(tfLoad.getText() + ".png") != null) {
    PImage image = loadImage(tfLoad.getText() + ".png");
    for (int i = 0; i <= numRows; i++) {
      for (int j = 0; j <= numCols; j++) {
        int xIndex = (int)map(j, 0, numCols + 1, 0, image.width);
        int yIndex = (int)map(i, 0, numRows + 1, 0, image.height);
        color col = image.get(xIndex, yIndex);

        float heightFromColor = map(red(col), 0, 255, 0, -1.0f);

        int vertIndex = i * (numCols + 1) + j;

        if (vertIndex < points.size()) {
          points.get(vertIndex).y = heightFromColor;
        }
      }
    }
  }
  generate = false;
}

void setColor(int i) {
  color curCol;
  float relativeHeight = abs(points.get(i).y) * heightMod / snowThreshold * -1;
  relativeHeight = abs(relativeHeight);
  // SNOW
  if (relativeHeight >= 0.8) {
    if (blendOn) {
      float ratio = (relativeHeight - 0.8) / 0.2f;
      curCol = lerpColor(rock, snow, ratio);
    } else {
      curCol = snow;
    }
  }
  // ROCK
  else if (relativeHeight >= 0.4 && relativeHeight < 0.8) {
    if (blendOn) {
      float ratio = (relativeHeight - 0.4f) / 0.4f;
      curCol = lerpColor(grass, rock, ratio);
    } else {
      curCol = rock;
    }
  }
  // GRASS
  else if (relativeHeight >= 0.2 && relativeHeight < 0.4) {
    if (blendOn) {
      float ratio = (relativeHeight - 0.2f) / 0.2f;
      curCol = lerpColor(dirt, grass, ratio);
    } else {
      curCol = grass;
    }
  }
  // WATER
  else {
    if (blendOn) {
      float ratio = relativeHeight / 0.2f;
      curCol = lerpColor(water, dirt, ratio);
    } else {
      curCol = water;
    }
  }
  fill(curCol);
}

void mouseDragged(MouseEvent event) {
  if (!cp.isMouseOver()) {
    phi += (mouseX - pmouseX) * 0.3f;
    if ((theta < 179 || mouseY - pmouseY < 0) && (theta > 1 || mouseY - pmouseY > 0)) {
      theta += (mouseY - pmouseY) * 0.3f;
    }
  }
}

void mouseWheel(MouseEvent event) {
  if (radius > 10 && radius < 200) {
    radius += event.getCount() * 10;
  } else if (radius == 200 && event.getCount() < 0) {
    radius += event.getCount() * 10;
  } else if (radius == 10 && event.getCount() > 0) {
    radius += event.getCount() * 10;
  }
  if (radius > 200) {
    radius = 200;
  } else if (radius < 10) {
    radius = 10;
  }
}
