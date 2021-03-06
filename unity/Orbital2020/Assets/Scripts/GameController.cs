﻿using System.Collections;
using System.Collections.Generic;
using System.Text;
using System;
using UnityEngine;
using UnityEngine.SceneManagement;

public class GameController : MonoBehaviour
{
    public InventoryItem selectedPlant;
    public GameObject plantableField;
    
    public GameObject gamePlantPrefab;
    public UIController uiController;
    public Grid grid;
    public Vector2Int fieldSize;
    public GameObject tilePrefab;

    public bool planting = false;
    public bool moveDeleting = false;

    public GameData gameData;

    public bool testing;
    public string testData;

    public GameObject defaultGameField;

    //List<PlantableTile> plantableTiles = new List<PlantableTile>();
    PlantableTile[,] plantableTiles;

    // Start is called before the first frame update
    void Start()
    {
        //Initialize plantable tiles
        plantableTiles = new PlantableTile[fieldSize.x,fieldSize.y];
        for(int x = 0; x < fieldSize.x; x++)
        {
            for(int y = 0; y < fieldSize.y; y++)
            {
                GameObject tileObject = Instantiate(tilePrefab, transform);
                tileObject.transform.position = grid.GetCellCenterWorld(new Vector3Int(x, y, 0));
                tileObject.name = "(" + x.ToString() + ", " + y.ToString() + ")";
                PlantableTile tileScript = tileObject.GetComponent<PlantableTile>();
                tileScript.gridPosition = new Vector2Int(x, y);
                //plantableTiles.Add(tileObject.GetComponent<PlantableTile>());
                plantableTiles[x,y] = tileScript;
            }
        }

        //For testing only
        if(testing)
        {
            SetGameData(testData);
        }
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    public void ResetGame()
    {
        SceneManager.LoadScene(SceneManager.GetActiveScene().name);
    }

    public void SetGameData(string json)
    {
        this.gameData = GameData.From(json);

        //Instantiate plant objects
        foreach (GamePlant plant in gameData.plants)
        {
            PlantableTile tile = plantableTiles[plant.gridX, plant.gridY];
            GameObject newPlant = Instantiate(gamePlantPrefab, tile.transform.position, Quaternion.identity, tile.transform);
            GamePlantObject plantScript = newPlant.GetComponent<GamePlantObject>();
            plantScript.initialize(plant, tile);
            plantScript.setDeleteCallback(() => onRemovePlant(plantScript.data));
            plantScript.setMoveCallback(() => onMovePlant(plantScript.data));
            tile.setPlant(plantScript);
        }
        
        uiController.UpdateGemDisplay(gameData.gemTotal);

        SaveGame();
    }

    public void GrowAndDrop(string focusTime)
    {
        gameData.focusDuration = int.Parse(focusTime);
        TimeSpan duration = new TimeSpan(0, gameData.focusDuration, 0);

        //Process plant growth
        GrowPlants(duration);

        DropGems(duration);

        //Reset idle tracker after processing the previous one
        gameData.focusDuration = 0;
    }

    public void OnTileClick(PlantableTile tile)
    {
        if (planting && !selectedPlant.Equals(null))
        {
            addPlant(tile);

            endPlant();
        }
    }

    public void addPlant(PlantableTile tile)
    {
        GameObject newPlant = Instantiate(gamePlantPrefab, tile.transform.position, Quaternion.identity, tile.transform);
        GamePlantObject plantScript = newPlant.GetComponent<GamePlantObject>();
        plantScript.initialize(new GamePlant(selectedPlant, tile), tile);
        plantScript.setDeleteCallback(() => onRemovePlant(plantScript.data));
        plantScript.setMoveCallback(() => onMovePlant(plantScript.data));
        tile.setPlant(plantScript);
        gameData.plants.Add(plantScript.data);
        gameData.inventory.Remove(selectedPlant);
        selectedPlant = null;

        SaveGame();
    }

    public void startPlant(InventoryItem plantData)
    {
        bool isFull = true;
        foreach(PlantableTile tile in plantableTiles)
        {
            if (!tile.isOccupied)
            {
                isFull = false;
                tile.displayAvailability();
            }
        }

        if (!isFull)
        {
            if (moveDeleting)
            {
                endMoveDelete();
            }
            planting = true;
            selectedPlant = plantData;
        }
        else
        {
            Debug.Log("Field is full!");
        }
    }

    public void endPlant()
    {
        planting = false;
        selectedPlant = null;
        foreach (PlantableTile tile in plantableTiles)
        {
            tile.stopDisplayAvailability();
        }
    }

    public void toggleMoveDelete()
    {
        if (moveDeleting)
        {
            endMoveDelete();
        }
        else
        {
            startMoveDelete();
        }
    }

    public void startMoveDelete()
    {
        bool isEmpty = true;

        foreach (PlantableTile tile in plantableTiles)
        {
            if (tile.plant)
            {
                isEmpty = false;
                tile.plant.startMoveDelete();
            }
        }

        if (!isEmpty)
        {
            if (planting)
            {
                endPlant();
            }
            moveDeleting = true;
        }
        else
        {
            Debug.Log("No Plants, nothing to move/delete");
        }
    }

    public void endMoveDelete()
    {
        moveDeleting = false;

        foreach (PlantableTile tile in plantableTiles)
        {
            if (tile.plant)
            {
                tile.plant.endMoveDelete();
            }
        }
    }

    public void obtainSeedPack(int amount)
    {
        //Generate
        //List<SeedPack> seedPacks = new List<SeedPack>();
        //seedPacks.Add(new SeedPack("testplant1"));
        //seedPacks.Add(new SeedPack("testplant2"));
        //seedPacks.Add(new SeedPack("testplant1"));
        //seedPacks.Add(new SeedPack("testplant2"));
        //seedPacks.Add(new SeedPack("testplant1"));

        //Test
        //List<SeedPack> seedPacks = new List<SeedPack>();
        //seedPacks.Add(new SeedPack("chrysanthemum"));
        //seedPacks.Add(new SeedPack("daisy"));
        //seedPacks.Add(new SeedPack("hydrangea"));
        //seedPacks.Add(new SeedPack("lavender"));
        //seedPacks.Add(new SeedPack("marigold"));
        //seedPacks.Add(new SeedPack("morning_glory"));
        //seedPacks.Add(new SeedPack("poppy"));
        //seedPacks.Add(new SeedPack("rose"));
        //seedPacks.Add(new SeedPack("shitake_mushroom"));
        //seedPacks.Add(new SeedPack("tulip"));

        List<SeedPack> seedPacks = new List<SeedPack>();
        for (int i = 0; i < amount; i++)
        {
            seedPacks.Add(PlantFactory.Instance().GenerateSeedPack());
        }

        //Activate UI
        uiController.OpenRewardsScreen(seedPacks);

        //Edit Collections
        foreach(SeedPack pack in seedPacks)
        {
            CollectionItem newItem = new CollectionItem(pack.plantType);
            if (!gameData.collection.Contains(newItem))
            {
                gameData.collection.Add(newItem);
            }
        }

        //Edit inventory
        foreach (SeedPack pack in seedPacks)
        {
            gameData.inventory.Add(new InventoryItem(pack.plantType));
        }
    }

    public void showCollection()
    {
        uiController.OpenCollectionScreen(gameData.collection);
    }

    public void showInventory()
    {
        uiController.OpenInventoryScreen(gameData.inventory);
    }

    public void onRemovePlant(GamePlant plant)
    {
        gameData.plants.Remove(plant);
        endMoveDelete();
        SaveGame();
    }

    public void onMovePlant(GamePlant plant)
    {
        SaveGame();
    }

    public void SaveGame()
    {
        string data = gameData.ToJson();
        FlutterMessageManager.Instance().sendGameData(data);
        Debug.Log(data);
    }

    public void GrowPlants(TimeSpan duration)
    {
        foreach (PlantableTile tile in plantableTiles)
        {
            if (tile.plant)
            {
                tile.plant.Grow(duration);
            }
        }
    }

    public void DropGems(TimeSpan duration)
    {
        foreach (PlantableTile tile in plantableTiles)
        {
            if (tile.plant)
            {
                tile.plant.DropGems(duration);
            }
        }
    }

    public void AddGem(int amount)
    {
        gameData.gemTotal += amount;
        uiController.UpdateGemDisplay(gameData.gemTotal);
        SaveGame();
    }
}
