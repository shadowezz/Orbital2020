﻿using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;
using Random = UnityEngine.Random;

public class GamePlantObject : MonoBehaviour, IPointerClickHandler, IDragHandler, IEndDragHandler
{
    public delegate void OnDeleteCallback();
    public delegate void OnMoveCallback();

    public SpriteRenderer spriteRenderer;
    public GameObject movingSprite;
    public OnDeleteCallback deleteCallback;
    public OnMoveCallback moveCallback;

    public GamePlant data;
    public bool moveDeleting;
    public Vector3 originalPosition;
    public PlantableTile tile;

    public void initialize(GamePlant plant, PlantableTile tile)
    {
        spriteRenderer = GetComponent<SpriteRenderer>();
        this.data = plant;
        this.originalPosition = transform.position;
        this.tile = tile;

        UpdateSprite();
    }

    public void OnPointerClick(PointerEventData eventData)
    {
        if (!eventData.dragging && !moveDeleting)
        {
            Grow(new TimeSpan(0, 0, 6));
        }
    }

    public void OnDrag(PointerEventData eventData)
    {
        if (moveDeleting)
        {
            Vector2 screenPosition = eventData.position;
            Vector3 worldPosition = Camera.main.ScreenToWorldPoint(screenPosition);
            worldPosition.z = 0;

            transform.position = worldPosition;

            gameObject.layer = LayerMask.NameToLayer("Dragging");
        }
    }

    public void OnEndDrag(PointerEventData eventData)
    {
        //this works because the plant being dragged is put in a "dragging" layer,
        //which is ignored by the raycasting camera
        if (moveDeleting)
        {
            GameObject destinationObject = eventData.pointerCurrentRaycast.gameObject;
            if (destinationObject)
            {
                GamePlantObject plant = destinationObject.GetComponent<GamePlantObject>();
                if (plant)
                {
                    //Dragged to plant
                    PlantableTile temp = this.tile;
                    movePlant(plant.tile, false);
                    plant.movePlant(temp, false);
                }

                PlantableTile newTile = destinationObject.GetComponent<PlantableTile>();
                if (newTile)
                {
                    //Dragged to empty tile
                    this.tile.clear();
                    movePlant(newTile);
                }
            }

            transform.position = originalPosition;
            gameObject.layer = LayerMask.NameToLayer("Default");
            moveCallback();
        }
    }

    public void Grow(TimeSpan duration)
    {
        if(data.growthStage >= PlantFactory.Instance().GetGrowthStages(data.plantType))
        {
            //Cannot grow any more
            return;
        }

        TimeSpan growthTime = PlantFactory.Instance().GetGrowthTime(data.plantType, data.growthStage);
        double totalGrowth = data.growthProgress + duration.TotalMinutes;

        if(totalGrowth >= growthTime.TotalMinutes)
        {
            data.growthStage++;
            UpdateSprite();
        }
        else
        {
            data.growthProgress = totalGrowth;
        }
    }

    public void DropGems(TimeSpan duration)
    {
        int dropRate = PlantFactory.Instance().GetGemDrop(data.plantType, data.growthStage);
        int dropMultiplier = duration.Minutes / 15;
        int totalDrop = dropMultiplier * dropRate;
        int dropLimit = PlantFactory.Instance().GetGemDropLimit(data.plantType);
        if (totalDrop > dropLimit)
        {
            totalDrop = dropLimit;
        }

        int[] gemNumbers = AmountToGemNumber(totalDrop);
        for(int i = 0; i < gemNumbers.Length; i++)
        {
            for(int j = 0; j < gemNumbers[i]; j++)
            {
                GameObject gemPrefab = PlantFactory.Instance().GetGemObject(i);
                Vector3 posOffset = Random.insideUnitCircle * 10;
                Instantiate(gemPrefab, transform.position + posOffset, Quaternion.identity, tile.transform);
            }
        }
    }

    void UpdateSprite()
    {
        spriteRenderer.sprite = PlantFactory.Instance()
            .GetGameSprites(data.plantType, data.growthStage);
    }

    public void startMoveDelete()
    {
        moveDeleting = true;
        movingSprite.SetActive(true);
    }

    public void endMoveDelete()
    {
        moveDeleting = false;
        movingSprite.SetActive(false);
    }

    public void setDeleteCallback(OnDeleteCallback callback)
    {
        this.deleteCallback = callback;
    }

    public void setMoveCallback(OnMoveCallback callback)
    {
        this.moveCallback = callback;
    }

    public void deletePlant()
    {
        deleteCallback();
        tile.clear();
        Destroy(gameObject);
    }

    public void movePlant(PlantableTile tile, bool clearOld = true)
    {
        transform.position = tile.transform.position;
        originalPosition = tile.transform.position;
        data.gridX = tile.gridPosition.x;
        data.gridY = tile.gridPosition.y;
        transform.parent = tile.transform;
        if (clearOld)
        {
            this.tile.clear();
        }
        this.tile = tile;
        tile.setPlant(this);
    }

    public override string ToString()
    {
        return base.ToString();
    }

    private int[] AmountToGemNumber(int amount)
    {
        int bigGem = Mathf.FloorToInt(amount / 10);
        amount = amount % 10;
        int gem = Mathf.FloorToInt(amount / 5);
        amount = amount % 5;
        int coin = amount;
        int[] gemNumbers = { coin, gem, bigGem};
        return gemNumbers;
    }
}
