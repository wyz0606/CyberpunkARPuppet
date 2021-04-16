using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;

public class InputManager : MonoBehaviour
{
    private PuppetLineController lineController;

    // Update is called once per frame
    void Update()
    {
        if (Input.GetMouseButton(0))
        {
            Ray ray = Camera.main.ScreenPointToRay(Input.mousePosition);
            RaycastHit hit;

            if (Physics.Raycast(ray, out hit))
            {
                
                if (hit.collider.CompareTag("PuppetLine"))
                {
                    lineController = hit.collider.GetComponent<PuppetLineController>();

                    lineController.IsActive = true;

                    lineController.FrameNobe.material.EnableKeyword("_HIGHLIGHTENABLED_ON");
                }
            }
        }
        if (Input.GetMouseButtonUp(0))
        {
            if (lineController != null)
            {
                lineController.IsActive = false;
                lineController.FrameNobe.material.DisableKeyword("_HIGHLIGHTENABLED_ON");
                lineController = null;
            }
        }

        if (Input.touchCount > 0)
        {
            if(Input.GetTouch(0).phase == TouchPhase.Stationary || Input.GetTouch(0).phase == TouchPhase.Moved)
            {
                Vector2 position;
                if(Input.GetMouseButton(0))
                {
                    position = Input.mousePosition;
                }
                else
                {
                    position = Input.GetTouch(0).position;
                }

                Ray ray = Camera.main.ScreenPointToRay(position);
                RaycastHit hit;

                if (Physics.Raycast(ray, out hit))
                {
                    if (hit.collider.CompareTag("PuppetLine"))
                    {
                        lineController = hit.collider.GetComponent<PuppetLineController>();

                        lineController.IsActive = true;

                        lineController.FrameNobe.material.EnableKeyword("_HIGHLIGHTENABLED_ON");
                    }
                }
            }

            if (Input.GetTouch(0).phase == TouchPhase.Ended)
            {
                if (lineController != null)
                {
                    lineController.IsActive = false;
                    lineController.FrameNobe.material.DisableKeyword("_HIGHLIGHTENABLED_ON");
                    lineController = null;
                }
            }
        }
    }
}
